{ config
, lib
, osConfig
, pkgs
, ...
}:
let
  inherit (lib)
    types

    escapeShellArgs
    foldr
    literalExpression
    makeBinPath
    mapAttrsToList

    mkEnableOption
    mkIf
    mkOption

    optional
    optionalAttrs
    optionalString
    recursiveUpdate
    toShellVar
    ;

  inherit (config.lib.nixos.systemdUtils.lib) mkPathSafeName;
in
{
  options.somasis.tunnels = {
    enable = mkEnableOption "Enable tunnels";

    tunnels = mkOption {
      type = types.attrsOf (types.submodule (
        { name, config, ... }: {
          options = {
            name = mkOption {
              type = types.nonEmptyStr;
              description = "Pretty name for use by other stuff";
              default = name;
              defaultText = literalExpression ''config.somasis.tunnels.tunnels.<name>.port'';
              example = "ircd";
            };

            type = mkOption {
              type = types.enum [ "local" "dynamic" ];
              description = "What type of tunnel to create: a local port forward (corresponding to ssh(1) option -L), or a dynamic port forward (corresponding to -D).";
              default = "local";
              example = "dynamic";
            };

            port = mkOption {
              type = types.ints.between 1025 65536;
              description = "Local port to use for tunnel";
              default = null;
              example = 9400;
            };

            remote = mkOption {
              type = types.nonEmptyStr;
              description = "Remote SSH host to create a tunnel to";
              default = null;
              example = "snowdenej@nsa.gov";
            };

            remoteHost = mkOption {
              type = types.nonEmptyStr;
              description = ''
                Remote host which the tunnel should direct to.

                Generally this should remain the default, unless you're using
                the tunnel to connect to a host which is inaccessible from
                outside the network the SSH host is on.
              '';
              default = "localhost";
              example = "192.168.1.1";
            };

            remotePort = mkOption {
              type = types.port;
              description = "Remote port to tunnel to (only does something when type == local)";
              default = config.port;
              defaultText = literalExpression ''config.somasis.tunnels.tunnels.<name>.port'';
              example = 9400;
            };

            linger = mkOption {
              type = types.nonEmptyStr;
              description = "How long the tunnel process should be kept around after its last connection (only does something when type == local)";
              default = "5m";
              example = "90s";
            };

            extraOptions = mkOption {
              type = with types; listOf str;
              description = "Extra arguments to pass to the ssh tunnel process";
              default = [ ];
              example = [ "-o" "ConnectTimeout=5" ];
            };
          };
        }
      ));

      description = "Set of tunnels to create";
      example = {
        ircd = {
          port = 9400;

          remote = "snowdenej@nsa.gov";
          remotePort = 9400;

          linger = "600s";
        };
      };

      default = { };
    };
  };

  config = mkIf config.somasis.tunnels.enable {
    systemd.user = foldr
      (
        tunnel:
        let
          target = "${tunnel.remote}:${tunnel.name}";

          # We can't simply use %t/tunnel/${target}.sock or ${target}, because `ssh`
          # doesn't correctly parse colons in the instance name in -L's syntax
          socket = "tunnel-${mkPathSafeName tunnel.remote}-${mkPathSafeName tunnel.name}.sock";
        in
        units:
        recursiveUpdate units {
          targets."tunnels-${mkPathSafeName tunnel.remote}" = {
            Unit = {
              Description = "Tunnels to ${tunnel.remote}";
              PartOf = [ "tunnels.target" ];
            };
            Install.WantedBy = [ "tunnels.target" ];
          };

          sockets."tunnel-proxy-${mkPathSafeName target}" = optionalAttrs (tunnel.type == "local") {
            Unit = {
              Description = "Listen for requests to connect to ${target}";
              PartOf = [ "tunnels-${mkPathSafeName tunnel.remote}.target" ];
            };
            Install.WantedBy = [ "tunnels-${mkPathSafeName tunnel.remote}.target" "sockets.target" ];

            Socket.ListenStream = [ tunnel.port ];
          };

          services."tunnel-proxy-${mkPathSafeName target}" = optionalAttrs (tunnel.type == "local") {
            Unit = {
              Description = "Serve requests to connect to ${target}";
              PartOf = [ "tunnels-${mkPathSafeName tunnel.remote}.target" ];

              # Stop when tunnel-proxy-*.service stops/is no longer listening for socket activation
              BindsTo = [
                "tunnel-proxy-${mkPathSafeName target}.socket"
                "tunnel-${mkPathSafeName target}.service"
              ];

              # Stop when tunnel-*.service stops
              After = [
                "tunnel-proxy-${mkPathSafeName target}.socket"
                "tunnel-${mkPathSafeName target}.service"
              ];
            };

            Service = {
              ProtectSystem = true;

              ExecStart = pkgs.writeShellScript "ssh-tunnel-listen-for-connection" ''
                PATH=${makeBinPath [ pkgs.coreutils pkgs.gawk pkgs.gnugrep pkgs.iproute2 ]}:"$PATH"

                : "''${XDG_RUNTIME_DIR:=/run/user/$(id -u)}"

                ${toShellVar "target" target}
                ${toShellVar "type" tunnel.type}
                ${toShellVar "linger" tunnel.linger}
                ${toShellVar "socket" socket}

                mkdir -p "$XDG_RUNTIME_DIR"/ssh-tunnel

                listen="$XDG_RUNTIME_DIR/ssh-tunnel/$socket"

                exec ${pkgs.systemd}/lib/systemd/systemd-socket-proxyd --exit-idle-time="$linger" "$listen"
              '';
            };
          };

          services."tunnel-${mkPathSafeName target}" = {
            Unit = {
              Description = "Open tunnel to ${target}";
              PartOf = [ "tunnels-${mkPathSafeName tunnel.remote}.target" ];

              After = [ "ssh-agent.service" ];
            }
            // optionalAttrs (tunnel.type == "local") { StopWhenUnneeded = true; }
            ;

            Service =
              let
                ssh-tunnel = pkgs.writeShellScript "ssh-tunnel" ''
                  set -euo pipefail

                  PATH=${makeBinPath [ pkgs.coreutils (config.programs.ssh.package or pkgs.openssh) ]}:"$PATH"

                  : "''${XDG_RUNTIME_DIR:=/run/user/$(id -u)}"

                  ${toShellVar "target" target}
                  ${toShellVar "type" tunnel.type}
                  ${toShellVar "port" tunnel.port}
                  ${toShellVar "remote_host" tunnel.remoteHost}
                  ${toShellVar "remote_port" tunnel.remotePort}
                  ${toShellVar "remote" tunnel.remote}
                  ${toShellVar "socket" socket}

                  mkdir -p "$XDG_RUNTIME_DIR"/ssh-tunnel

                  ssh_args=(
                      # Fork only once the forwards have been established successfully.
                      -f
                      -o ExitOnForwardFailure=yes

                      # Automation-related
                      -o BatchMode=yes
                      -o KbdInteractiveAuthentication=yes

                      # Hardening-related
                      -o StrictHostKeyChecking=no # Never connect when host has new keys
                      -o UpdateHostKeys=yes # *Do* accept graceful key rotation
                      -o CheckHostIP=yes # Defend against DNS spoofing

                      # Disable various things that do not deal with the tunnel.
                      -N # Don't run any commands
                      -T # Don't allocate a terminal
                      -a # Don't forward ssh-agent
                      -x # Don't forward Xorg
                      -k # Don't forward GSSAPI credentials
                  )

                  case "$type" in
                      "dynamic")
                          ssh_args+=( -D "localhost:$port" )
                          ;;
                      "local")
                          listen="$XDG_RUNTIME_DIR"/ssh-tunnel/"$socket":"$remote_host":"$remote_port"
                          ssh_args+=( -L "$listen" )
                          ;;
                  esac

                  ${optionalString (tunnel.extraOptions != []) "ssh_args+=( ${escapeShellArgs tunnel.extraOptions} )"}
                  ssh_args+=( "$remote" )

                  exec ssh "''${ssh_args[@]}"
                '';
              in
              {
                # Forking is used because it allows us to know exactly when the
                # forwards have been established successfully. Otherwise, the
                # socket's first request might not end up being served.
                Type = "forking";

                ExecStart = ssh-tunnel;
                ExecStopPost = optional (tunnel.type == "local") "${pkgs.coreutils}/bin/rm -f %t/ssh-tunnel/${socket}";

                Restart = "on-failure";
              }
              // optionalAttrs osConfig.networking.networkmanager.enable { ExecStartPre = [ "${pkgs.networkmanager}/bin/nm-online -q" ]; }
            ;
          }
          // optionalAttrs (tunnel.type == "dynamic") { Install.WantedBy = [ "tunnels-${mkPathSafeName tunnel.remote}.target" ]; }
          ;
        }
      )
      {
        targets.tunnels = {
          Unit = {
            Description = "All tunnels";
            PartOf = [ "default.target" ];
          };

          Install.WantedBy = [ "default.target" ];
        };
      }
      (mapAttrsToList (n: v: v) config.somasis.tunnels.tunnels)
    ;
  };
}

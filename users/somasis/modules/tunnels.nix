{ config
, lib
, osConfig
, pkgs
, ...
}:
with lib;
{
  options = {
    somasis.tunnels = {
      enable = mkEnableOption "Enable tunnels";

      tunnels = mkOption {
        type = types.attrsOf (types.submodule (
          { name, config, ... }: {
            options = {
              name = mkOption {
                type = types.str;
                description = "Pretty name for use by other stuff";
                default = name;
                defaultText = literalExpression ''config.somasis.tunnels.tunnels.<name>.port'';
                example = "ircd";
              };

              type = mkOption {
                type = types.enum [ "local" "dynamic" ];
                description = "What type of tunnel to create; a local port forward (see option -L on ssh(1)), or a dynamic port forward (see option -D on ssh(1))";
                default = "local";
                example = "dynamic";
              };

              port = mkOption {
                type = types.int;
                description = "Local port to use for tunnel";
                default = null;
                example = 9400;
              };

              remote = mkOption {
                type = types.str;
                description = "Remote SSH host to create a tunnel to";
                default = null;
                example = "snowdenej@nsa.gov";
              };

              remotePort = mkOption {
                type = types.int;
                description = "Remote port to tunnel to (only does something when type == local)";
                default = config.port;
                defaultText = literalExpression ''config.somasis.tunnels.tunnels.<name>.port'';
                example = 9400;
              };

              linger = mkOption {
                type = types.str;
                description = "How long the tunnel process should be kept around after its last connection (only does something when type == local)";
                default = "5m";
                example = "90s";
              };

              extraOptions = mkOption {
                type = with types; listOf nonEmptyStr;
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
  };

  config = mkIf config.somasis.tunnels.enable {
    systemd.user = lib.foldr
      (
        tunnel:
        let
          target = "${tunnel.remote}:${tunnel.name}";

          # We can't simply use %t/tunnel/${target}.sock or ${target}, because `ssh`
          # doesn't correctly parse colons in the instance name in -L's syntax
          socket = "tunnel-${tunnel.remote}-${toString tunnel.name}.sock";
        in
        units:
        lib.recursiveUpdate units {
          targets."tunnels@${tunnel.remote}" = {
            Unit = {
              Description = "Tunnels to ${tunnel.remote}";
              PartOf = [ "tunnels.target" ];
            };
            Install.WantedBy = [ "tunnels.target" ];
          };

          sockets."tunnel-proxy@${target}" = lib.optionalAttrs (tunnel.type == "local") {
            Unit = {
              Description = "Listen for requests to connect to ${target}";
              PartOf = [ "tunnels@${tunnel.remote}.target" ];
            };
            Install.WantedBy = [ "tunnels@${tunnel.remote}.target" "sockets.target" ];

            Socket.ListenStream = [ tunnel.port ];
          };

          services."tunnel-proxy@${target}" = lib.optionalAttrs (tunnel.type == "local") {
            Unit = {
              Description = "Serve requests to connect to ${target}";
              PartOf = [ "tunnels@${tunnel.remote}.target" ];

              # Stop when tunnel-proxy@*.service stops/is no longer listening for socket activation
              BindsTo = [
                "tunnel-proxy@${target}.socket"
                "tunnel@${target}.service"
              ];

              # Stop when tunnel@*.service stops
              After = [
                "tunnel-proxy@${target}.socket"
                "tunnel@${target}.service"
              ];
            };

            Service = {
              ProtectSystem = true;

              ExecStart = pkgs.writeShellScript "ssh-tunnel-listen-for-connection" ''
                PATH=${lib.makeBinPath [ pkgs.coreutils pkgs.gawk pkgs.gnugrep pkgs.iproute2 ]}:"$PATH"

                : "''${XDG_RUNTIME_DIR:=/run/user/$(id -u)}"

                ${lib.toShellVar "target" target}
                ${lib.toShellVar "type" tunnel.type}
                ${lib.toShellVar "linger" tunnel.linger}
                ${lib.toShellVar "socket" socket}

                mkdir -p "$XDG_RUNTIME_DIR"/ssh-tunnel

                listen="$XDG_RUNTIME_DIR/ssh-tunnel/$socket"

                exec ${pkgs.systemd}/lib/systemd/systemd-socket-proxyd --exit-idle-time="$linger" "$listen"
              '';
            };
          };

          services."tunnel@${target}" = {
            Unit = {
              Description = "Open tunnel to ${target}";
              PartOf = [ "tunnels@${tunnel.remote}.target" ];

              After = [ "ssh-agent.service" ];
            }
            // lib.optionalAttrs (tunnel.type == "local") { StopWhenUnneeded = true; }
            ;

            Service =
              let
                ssh-tunnel = pkgs.writeShellScript "ssh-tunnel" ''
                  PATH=${lib.makeBinPath [ pkgs.coreutils (config.programs.ssh.package or pkgs.openssh) ]}:"$PATH"

                  : "''${XDG_RUNTIME_DIR:=/run/user/$(id -u)}"

                  ${lib.toShellVar "target" target}
                  ${lib.toShellVar "type" tunnel.type}
                  ${lib.toShellVar "port" tunnel.port}
                  ${lib.toShellVar "remote_port" tunnel.remotePort}
                  ${lib.toShellVar "remote" tunnel.remote}
                  ${lib.toShellVar "socket" socket}

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
                          listen="$XDG_RUNTIME_DIR"/ssh-tunnel/"$socket":localhost:"$remote_port"
                          ssh_args+=( -L "$listen" )
                          ;;
                  esac

                  ${lib.optionalString (tunnel.extraOptions != []) "ssh_args+=( ${lib.escapeShellArgs tunnel.extraOptions} )"}
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
                ExecStopPost = lib.optional (tunnel.type == "local") "${pkgs.coreutils}/bin/rm -f %t/ssh-tunnel/${socket}";

                Restart = "on-failure";
              }
              // lib.optionalAttrs osConfig.networking.networkmanager.enable { ExecStartPre = [ "${pkgs.networkmanager}/bin/nm-online -q" ]; }
            ;
          }
          // lib.optionalAttrs (tunnel.type == "dynamic") { Install.WantedBy = [ "tunnels@${tunnel.remote}.target" ]; }
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
      (lib.mapAttrsToList (n: v: v) config.somasis.tunnels.tunnels)
    ;
  };
}


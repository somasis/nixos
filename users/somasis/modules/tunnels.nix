{ config, lib, pkgs, ... }:
with lib;
{
  options = {
    somasis.tunnels = {
      enable = mkEnableOption "Enable tunnels";

      tunnels = mkOption {
        type = types.listOf (types.submodule (
          { config, ... }: {
            options = {
              location = mkOption {
                type = types.int;
                description = "Local port to use for connecting to port on remote";
                default = null;
                example = 9400;
              };

              remote = mkOption {
                type = types.str;
                description = "Remote SSH host to create a tunnel to";
                default = null;
                example = "snowdenej@nsa.gov";
              };

              name = mkOption {
                type = types.str;
                description = "Pretty name for use by other stuff";
                default = config.location;
                defaultText = literalExpression ''config.somasis.tunnels.tunnels.<name>.location'';
                example = "ircd";
              };

              remoteLocation = mkOption {
                type = types.int;
                description = "Remote port that will be accessible at on the local port";
                default = config.location;
                defaultText = literalExpression ''config.somasis.tunnels.tunnels.<name>.location'';
                example = 9400;
              };

              linger = mkOption {
                type = types.str;
                description = "How long the tunnel process should be kept around after its last connection";
                default = "5m";
                example = "90s";
              };
            };
          }
        ));

        description = "List of tunnels to create";
        example = [
          {
            name = "ircd";

            location = 9400;

            remote = "snowdenej@nsa.gov";
            remoteLocation = 9400;

            linger = "600s";
          }
        ];

        default = [ ];
        defaultText = literalExpression "[]";
      };
    };
  };

  config = mkIf (config.somasis.tunnels.enable) {
    systemd.user = (foldr
      (
        tunnel:
        let
          target = "${tunnel.remote}:${tunnel.name}";

          # We can't simply use %t/tunnel/${target}.sock or ${target}, because `ssh`
          # doesn't correctly parse colons in the instance name in -L's syntax
          socket = "${tunnel.remote}-${toString tunnel.name}.sock";
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

          sockets."tunnel-proxy@${target}" = {
            Unit = {
              Description = "Listen for requests to connect to ${target}";
              PartOf = [ "tunnels@${tunnel.remote}.target" ];
            };
            Install.WantedBy = [ "tunnels@${tunnel.remote}.target" "sockets.target" ];

            Socket.ListenStream = [ tunnel.location ];
          };

          services."tunnel-proxy@${target}" = {
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

              ExecStart = [
                "${pkgs.systemd}/lib/systemd/systemd-socket-proxyd --exit-idle-time=${tunnel.linger} %t/tunnel/${socket}"
              ];
            };
          };

          services."tunnel@${target}" = {
            Unit = {
              Description = "Open tunnel to ${target}";
              PartOf = [ "tunnels@${tunnel.remote}.target" ];

              After = [ "ssh-agent.service" ];

              StopWhenUnneeded = true;
            };

            Service =
              let
                ssh = lib.concatStringsSep " " [
                  "${pkgs.openssh}/bin/ssh"

                  # Fork only once the forwards have been established successfully.
                  "-f"
                  "-o ExitOnForwardFailure=yes"

                  # Automation-related
                  "-o BatchMode=yes"

                  # Hardening-related
                  "-o StrictHostKeyChecking=no" # Never connect when host has new keys
                  "-o UpdateHostKeys=yes" # *Do* accept graceful key rotation
                  "-o CheckHostIP=yes" # Defend against DNS spoofing

                  # Disable various things that do not deal with the tunnel.
                  "-N" # Don't run any commands
                  "-T" # Don't allocate a terminal
                  "-a" # Don't forward ssh-agent
                  "-x" # Don't forward Xorg
                  "-k" # Don't forward GSSAPI credentials

                  # (if type == "dynamic" then
                  #   "-D %t/tunnel/${socket}:${target.location}"
                  # else # if type == "local" then
                  "-L %t/tunnel/${socket}:localhost:${toString tunnel.remoteLocation}"
                  # )
                ];
              in
              {
                # Forking is used because it allows us to know exactly when the
                # forwards have been established successfully. Otherwise, the
                # socket's first request might not end up being served.
                Type = "forking";

                ProtectSystem = true;

                ExecStartPre = [ "${pkgs.networkmanager}/bin/nm-online -q" ];
                ExecStart = [ "-${ssh} ${tunnel.remote}" ];
                ExecStopPost = [ "${pkgs.coreutils}/bin/rm -f %t/tunnel/${socket}" ];

                Restart = "on-failure";
              };
          };
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
      config.somasis.tunnels.tunnels
    );
  };
}

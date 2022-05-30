{ config, lib, pkgs, ... }:
with lib;
let
  sshTunnel = pkgs.writeShellScript "sshTunnel" ''
    ${pkgs.s6-portable-utils}/bin/s6-pause \
        | ${pkgs.openssh}/bin/ssh -NTax \
            -o BatchMode=yes \
            -o ControlMaster=yes \
            -o ExitOnForwardFailure=yes \
            -o TCPKeepAlive=no \
            -o ServerAliveInterval=15 \
            "$@"
  '';
in
{
  options = {
    somasis.tunnels = {
      enable = mkEnableOption "Enable tunnels";
      ssh = mkOption {
        type = types.listOf types.str;
        default = [ ];
        defaultText = literalExpression "[]";
        description = "List of hosts that SSH tunnels should be started for";
        example = [ "ssh.cia.gov" "scab.pinkerton.com" ];
      };
    };
  };

  config = mkIf (config.somasis.tunnels.enable) {
    systemd.user.targets = {
      tunnels = {
        Unit = {
          Description = "All tunnels";
          PartOf = [ "default.target" ];
        };

        Install.WantedBy = [ "default.target" ];
      };

      tunnels-ssh = {
        Unit = {
          Description = "All ssh(1) tunnels";
          PartOf = [ "tunnels.target" ];
          After = [ "ssh-agent.service" ];
        };

        Install.WantedBy = [ "tunnels.target" ];
      };
    };

    systemd.user.services = foldr
      (name: acc: acc //
        {
          "tunnel@${name}" = {
            Service = {
              ExecStart = "${sshTunnel} %i";
              Restart = "always";
              RestartSec = 10;
            };

            Unit = {
              StartLimitIntervalSec = "30s";
              StartLimitBurst = "2";
              PartOf = [ "tunnels-ssh.target" ];
              After = [ "ssh-agent.service" ];
            };

            Install.WantedBy = [ "tunnels-ssh.target" ];
          };
        })
      { }
      config.somasis.tunnels.ssh;
  };
}

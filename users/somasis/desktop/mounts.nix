{ config
, pkgs
, lib
, ...
}:
{
  home.packages = [
    pkgs.rclone
    pkgs.sshfs
  ];

  home.persistence."/persist${config.home.homeDirectory}".directories = [ "etc/rclone" ];

  # systemd.user.tmpfiles.rules = [
  #   "L+ ${config.home.homeDirectory}/vault - - - - ${config.home.homeDirectory}/mnt/sftp/spinoza.7596ff.com_raid/backup/vault"
  # ];

  # TODO This really ought to be templated.
  systemd.user = {
    targets = {
      mounts = {
        Unit = {
          Description = "All mounts";
          PartOf = [ "default.target" ];
        };
        Install.WantedBy = [ "default.target" ];
      };

      gdrive = {
        Unit = {
          Description = "All Google Drive mounts";
          PartOf = [ "mounts.target" ];
        };
        Install.WantedBy = [ "mounts.target" ];
      };

      gphotos = {
        Unit = {
          Description = "All Google Photos mounts";
          PartOf = [ "mounts.target" ];
        };
        Install.WantedBy = [ "mounts.target" ];
      };

      sftp = {
        Unit = {
          Description = "All SFTP mounts";
          PartOf = [ "mounts.target" ];
        };
        Install.WantedBy = [ "mounts.target" ];
      };
    };

    mounts = {
      "home-somasis-mnt-sftp-genesis.whatbox.ca" =
        let
          What = "somasis@genesis.whatbox.ca:";
          Where = "${config.home.homeDirectory}/mnt/sftp/genesis.whatbox.ca";
        in
        {
          Unit = {
            Description = "Mount '${What}' at ${Where}";
            PartOf = [ "sftp.target" ];
          };
          Install.WantedBy = [ "sftp.target" ];

          Mount = {
            Type = "fuse.sshfs";
            inherit What Where;

            Options = (lib.concatStringsSep "," [
              "_netdev"
              "compression=yes"
              "dir_cache=yes"
              "idmap=user"
              "max_conns=4"
              "follow_symlinks"
              "delay_connect"
              "reconnect"
            ]);
          };
        };

      "home-somasis-mnt-sftp-lacan.somas.is" =
        let
          What = "somasis@lacan.somas.is:";
          Where = "${config.home.homeDirectory}/mnt/sftp/lacan.somas.is";
        in
        {
          Unit = {
            Description = "Mount '${What}' at ${Where}";
            PartOf = [ "sftp.target" ];
          };
          Install.WantedBy = [ "sftp.target" ];

          Mount = {
            Type = "fuse.sshfs";
            inherit What Where;

            Options = (lib.concatStringsSep "," [
              "_netdev"
              "compression=yes"
              "dir_cache=yes"
              "idmap=user"
              "max_conns=4"
              "follow_symlinks"
              "delay_connect"
              "reconnect"
            ]);
          };
        };

      "home-somasis-mnt-sftp-spinoza.7596ff.com" =
        let
          What = "somasis@spinoza.7596ff.com:";
          Where = "${config.home.homeDirectory}/mnt/sftp/spinoza.7596ff.com";
        in
        {
          Unit = {
            Description = "Mount '${What}' at ${Where}";
            PartOf = [ "sftp.target" ];
          };
          Install.WantedBy = [ "sftp.target" ];

          Mount = {
            Type = "fuse.sshfs";
            inherit What Where;

            Options = (lib.concatStringsSep "," [
              "_netdev"
              "compression=yes"
              "dir_cache=yes"
              "idmap=user"
              "max_conns=4"
              "follow_symlinks"
              "delay_connect"
              "reconnect"
            ]);
          };
        };

      "home-somasis-mnt-sftp-spinoza.7596ff.com_raid" =
        let
          What = "somasis@spinoza.7596ff.com:/mnt/raid/somasis";
          Where = "${config.home.homeDirectory}/mnt/sftp/spinoza.7596ff.com_raid";
        in
        {
          Unit = {
            Description = "Mount '${What}' at ${Where}";
            PartOf = [ "sftp.target" ];
          };
          Install.WantedBy = [ "sftp.target" ];

          Mount = {
            inherit What Where;
            Type = "fuse.sshfs";

            Options = (lib.concatStringsSep "," [
              "_netdev"
              "compression=yes"
              "dir_cache=yes"
              "idmap=user"
              "max_conns=4"
              "follow_symlinks"
              "delay_connect"
              "reconnect"
            ]);
          };
        };
    };

    services = {
      "rclone@home-somasis-mnt-gdrive-personal" = {
        Unit = {
          Description = ''Mount rclone remote "gdrive-personal:" at ${config.home.homeDirectory}/mnt/gdrive/personal'';
          PartOf = [ "gdrive.target" ];
        };
        Install.WantedBy = [ "gdrive.target" ];

        Service = {
          Type = "notify";
          ExecStartPre = [ "${pkgs.coreutils}/bin/mkdir -p ${config.home.homeDirectory}/mnt/gdrive/personal" ];
          ExecStart = [
            "${pkgs.rclone}/bin/rclone mount --poll-interval=30m --vfs-cache-mode=writes gdrive-personal: ${config.home.homeDirectory}/mnt/gdrive/personal"
          ];
          ExecStopPost = [ "-${pkgs.coreutils}/bin/rmdir -p ${config.home.homeDirectory}/mnt/gdrive/personal" ];
        };
      };

      "rclone@home-somasis-mnt-gdrive-appstate" = {
        Unit = {
          Description = ''Mount rclone remote "gdrive-appstate:" at ${config.home.homeDirectory}/mnt/gdrive/appstate'';
          PartOf = [ "gdrive.target" ];
        };
        Install.WantedBy = [ "gdrive.target" ];

        Service = {
          Type = "notify";
          ExecStartPre = [ "${pkgs.coreutils}/bin/mkdir -p ${config.home.homeDirectory}/mnt/gdrive/appstate" ];
          ExecStart = [
            "${pkgs.rclone}/bin/rclone mount --poll-interval=30m --vfs-cache-mode=writes gdrive-appstate: ${config.home.homeDirectory}/mnt/gdrive/appstate"
          ];
          ExecStopPost = [ "-${pkgs.coreutils}/bin/rmdir -p ${config.home.homeDirectory}/mnt/gdrive/appstate" ];
        };
      };

      "rclone@home-somasis-mnt-gphotos-personal" = {
        Unit = {
          Description = ''Mount rclone remote "gphotos-personal:" at ${config.home.homeDirectory}/mnt/gphotos/personal'';
          PartOf = [ "gphotos.target" ];
        };
        Install.WantedBy = [ "gphotos.target" ];

        Service = {
          Type = "notify";
          ExecStartPre = [ "${pkgs.coreutils}/bin/mkdir -p ${config.home.homeDirectory}/mnt/gphotos/personal" ];
          ExecStart = [
            "${pkgs.rclone}/bin/rclone mount gphotos-personal: ${config.home.homeDirectory}/mnt/gphotos/personal"
          ];
          ExecStopPost = [ "-${pkgs.coreutils}/bin/rmdir -p ${config.home.homeDirectory}/mnt/gphotos/personal" ];
        };
      };
    };
  };
}

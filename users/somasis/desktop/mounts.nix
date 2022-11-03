{ config
, pkgs
, ...
}:
let
  home = config.home.homeDirectory;
in
{
  home.packages = [
    pkgs.rclone
    pkgs.sshfs
  ];

  home.persistence."/persist${config.home.homeDirectory}".directories = [ "etc/rclone" ];

  systemd.user.tmpfiles.rules = [
    # "L+ ${home}/audio/library/lossless - - - - ${home}/mnt/ssh/spinoza.7596ff.com_raid/somasis/audio/library/lossless"
    # "L+ ${home}/audio/library/source - - - - ${home}/mnt/ssh/spinoza.7596ff.com_raid/somasis/audio/library/source"
    "L+ ${home}/vault - - - - ${home}/mnt/ssh/spinoza.7596ff.com_raid/somasis/backup/vault"
  ];

  # TODO This really ought to be templated.
  systemd.user = {
    targets = {
      sshfs = {
        Unit = {
          Description = "All sshfs mounts";
          PartOf = [ "mounts.target" ];
        };
        Install.WantedBy = [ "mounts.target" ];
      };

      rclone = {
        Unit = {
          Description = "All rclone mounts";
          PartOf = [ "mounts.target" ];
        };
        Install.WantedBy = [ "mounts.target" ];
      };

      rclone-gdrive = {
        Unit = {
          Description = "All Google Drive rclone mounts";
          PartOf = [ "rclone.target" ];
        };
        Install.WantedBy = [ "rclone.target" ];
      };

      rclone-gphotos = {
        Unit = {
          Description = "All Google Photos rclone mounts";
          PartOf = [ "rclone.target" ];
        };
        Install.WantedBy = [ "rclone.target" ];
      };
    };

    mounts = {
      "home-somasis-mnt-ssh-genesis.whatbox.ca" =
        let
          What = "somasis@genesis.whatbox.ca:";
          Where = "${home}/mnt/ssh/genesis.whatbox.ca";
        in
        {
          Unit = {
            Description = "Mount '${What}' at ${Where}";
            PartOf = [ "sshfs.target" ];
          };
          Install.WantedBy = [ "sshfs.target" ];

          Mount = {
            Type = "fuse.sshfs";
            inherit What Where;

            Options = [
              "_netdev"
              "compression=yes"
              "dir_cache=yes"
              "idmap=user"
              "max_conns=4"
              "transform_symlinks"
            ];
          };
        };

      "home-somasis-mnt-ssh-lacan.somas.is" =
        let
          What = "somasis@lacan.somas.is:/";
          Where = "${home}/mnt/ssh/lacan.somas.is";
        in
        {
          Unit = {
            Description = "Mount '${What}' at ${Where}";
            PartOf = [ "sshfs.target" ];
          };
          Install.WantedBy = [ "sshfs.target" ];

          Mount = {
            Type = "fuse.sshfs";
            inherit What Where;

            Options = [
              "_netdev"
              "compression=yes"
              "dir_cache=yes"
              "idmap=user"
              "max_conns=4"
              "transform_symlinks"
            ];
          };
        };

      "home-somasis-mnt-ssh-spinoza.7596ff.com" =
        let
          What = "somasis@spinoza.7596ff.com:/";
          Where = "${home}/mnt/ssh/spinoza.7596ff.com";
        in
        {
          Unit = {
            Description = "Mount '${What}' at ${Where}";
            PartOf = [ "sshfs.target" ];
          };
          Install.WantedBy = [ "sshfs.target" ];

          Mount = {
            Type = "fuse.sshfs";
            inherit What Where;

            Options = [
              "_netdev"
              "compression=yes"
              "dir_cache=yes"
              "idmap=user"
              "max_conns=4"
              "transform_symlinks"
            ];
          };
        };

      "home-somasis-mnt-ssh-spinoza.7596ff.com_raid" =
        let
          What = "somasis@spinoza.7596ff.com:/mnt/raid";
          Where = "${home}/mnt/ssh/spinoza.7596ff.com_raid";
        in
        {
          Unit = {
            Description = "Mount '${What}' at ${Where}";
            PartOf = [ "sshfs.target" ];
          };
          Install.WantedBy = [ "sshfs.target" ];

          Mount = {
            inherit What Where;
            Type = "fuse.sshfs";

            Options = [
              "_netdev"
              "compression=yes"
              "dir_cache=yes"
              "idmap=user"
              "max_conns=4"
              "transform_symlinks"
            ];
          };
        };
    };

    services = {
      "rclone@home-somasis-mnt-gdrive-personal" = {
        Unit = {
          Description = ''Mount rclone remote "gdrive-personal" at ${home}/mnt/gdrive/personal'';
          PartOf = [ "rclone-gdrive.target" ];
        };
        Install.WantedBy = [ "rclone-gdrive.target" ];

        Service = {
          Type = "notify";
          ExecStartPre = [ "${pkgs.coreutils}/bin/mkdir -p ${home}/mnt/gdrive/personal" ];
          ExecStart = [
            "${pkgs.rclone}/bin/rclone mount --poll-interval=30m --vfs-cache-mode=writes gdrive-personal: ${home}/mnt/gdrive/personal"
          ];
          ExecStopPost = [ "-${pkgs.coreutils}/bin/rmdir -p ${home}/mnt/gdrive/personal" ];
        };
      };

      "rclone@home-somasis-mnt-gdrive-appstate" = {
        Unit = {
          Description = ''Mount rclone remote "gdrive-appstate" at ${home}/mnt/gdrive/appstate'';
          PartOf = [ "rclone-gdrive.target" ];
        };
        Install.WantedBy = [ "rclone-gdrive.target" ];

        Service = {
          Type = "notify";
          ExecStartPre = [ "${pkgs.coreutils}/bin/mkdir -p ${home}/mnt/gdrive/appstate" ];
          ExecStart = [
            "${pkgs.rclone}/bin/rclone mount --poll-interval=30m --vfs-cache-mode=writes gdrive-appstate: ${home}/mnt/gdrive/appstate"
          ];
          ExecStopPost = [ "-${pkgs.coreutils}/bin/rmdir -p ${home}/mnt/gdrive/appstate" ];
        };
      };

      "rclone@home-somasis-mnt-gphotos-personal" = {
        Unit = {
          Description = ''Mount rclone remote "gphotos-personal" at ${home}/mnt/gphotos/personal'';
          PartOf = [ "rclone-gphotos.target" ];
        };
        Install.WantedBy = [ "rclone-gphotos.target" ];

        Service = {
          Type = "notify";
          ExecStartPre = [ "${pkgs.coreutils}/bin/mkdir -p ${home}/mnt/gphotos/personal" ];
          ExecStart = [
            "${pkgs.rclone}/bin/rclone mount gphotos-personal: ${home}/mnt/gphotos/personal"
          ];
          ExecStopPost = [ "-${pkgs.coreutils}/bin/rmdir -p ${home}/mnt/gphotos/personal" ];
        };
      };
    };
  };
}

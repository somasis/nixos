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
    };

    mounts = {
      "home-somasis-mnt-ssh-genesis.whatbox.ca" = {
        Unit.PartOf = [ "sshfs.target" ];
        Install.WantedBy = [ "sshfs.target" ];

        Mount = {
          Type = "sshfs";
          What = "somasis@genesis.whatbox.ca:";
          Where = "${home}/mnt/ssh/genesis.whatbox.ca";

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

      "home-somasis-mnt-ssh-lacan.somas.is" = {
        Unit.PartOf = [ "sshfs.target" ];
        Install.WantedBy = [ "sshfs.target" ];

        Mount = {
          Type = "sshfs";
          What = "somasis@lacan.somas.is:/";
          Where = "${home}/mnt/ssh/lacan.somas.is";

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

      "home-somasis-mnt-ssh-spinoza.7596ff.com" = {
        Unit.PartOf = [ "sshfs.target" ];
        Install.WantedBy = [ "sshfs.target" ];

        Mount = {
          Type = "sshfs";
          What = "somasis@spinoza.7596ff.com:/";
          Where = "${home}/mnt/ssh/spinoza.7596ff.com";

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

      "home-somasis-mnt-ssh-spinoza.7596ff.com_raid" = {
        Unit.PartOf = [ "sshfs.target" ];
        Install.WantedBy = [ "sshfs.target" ];

        Mount = {
          Type = "sshfs";
          What = "somasis@spinoza.7596ff.com:/mnt/raid";
          Where = "${home}/mnt/ssh/spinoza.7596ff.com_raid";

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
          PartOf = [ "gdrive.target" ];
        };
        Install.WantedBy = [ "gdrive.target" ];

        Service = {
          Type = "notify";
          ExecStart = [
            "${pkgs.rclone}/bin/rclone --poll-interval=30m --vfs-cache-mode=writes gdrive-personal: ${home}/mnt/gdrive/personal"
          ];
        };
      };

      "rclone@home-somasis-mnt-gdrive-appstate" = {
        Unit = {
          Description = ''Mount rclone remote "gdrive-appstate" at ${home}/mnt/gdrive/appstate'';
          PartOf = [ "gdrive.target" ];
        };
        Install.WantedBy = [ "gdrive.target" ];

        Service = {
          Type = "notify";
          ExecStart = [
            "${pkgs.rclone}/bin/rclone --poll-interval=30m --vfs-cache-mode=writes gdrive-appstate: ${home}/mnt/gdrive/appstate"
          ];
        };
      };

      "rclone@home-somasis-mnt-gphotos-personal" = {
        Unit = {
          Description = ''Mount rclone remote "gphotos-personal" at ${home}/mnt/gphotos/personal'';
          PartOf = [ "gphotos.target" ];
        };
        Install.WantedBy = [ "gphotos.target" ];

        Service = {
          Type = "notify";
          ExecStart = [
            "${pkgs.rclone}/bin/rclone gphotos-personal: ${home}/mnt/gphotos/personal"
          ];
        };
      };
    };
  };
}

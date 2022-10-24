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
  systemd.user.mounts = {
    "home-somasis-mnt-ssh-genesis.whatbox.ca" = {
      Unit.PartOf = [ "mounts.target" ];
      Install.WantedBy = [ "mounts.target" ];

      Mount = {
        Type = "fuse.sshfs";
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
      Unit.PartOf = [ "mounts.target" ];
      Install.WantedBy = [ "mounts.target" ];

      Mount = {
        Type = "fuse.sshfs";
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
      Unit.PartOf = [ "mounts.target" ];
      Install.WantedBy = [ "mounts.target" ];

      Mount = {
        Type = "fuse.sshfs";
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
      Unit.PartOf = [ "mounts.target" ];
      Install.WantedBy = [ "mounts.target" ];

      Mount = {
        Type = "fuse.sshfs";
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

    "home-somasis-mnt-gdrive-personal" = {
      Unit.PartOf = [ "mounts.target" ];
      Install.WantedBy = [ "mounts.target" ];

      Mount = {
        Type = "fuse.rclone";
        What = "gdrive-personal:";
        Where = "${home}/mnt/gdrive/personal";

        Options = [
          "_netdev"
          "poll-interval=30m"
          "vfs-cache-mode=writes"
        ];
      };
    };

    "home-somasis-mnt-gdrive-appstate" = {
      Unit.PartOf = [ "mounts.target" ];
      Install.WantedBy = [ "mounts.target" ];

      Mount = {
        Type = "fuse.rclone";
        What = "gdrive-appstate:";
        Where = "${home}/mnt/gdrive/appstate";

        Options = [
          "_netdev"
          "poll-interval=30m"
          "vfs-cache-mode=writes"
        ];
      };
    };

    "home-somasis-mnt-gphotos-personal" = {
      Unit.PartOf = [ "mounts.target" ];
      Install.WantedBy = [ "mounts.target" ];

      Mount = {
        Type = "fuse.rclone";
        What = "gphotos-personal:";
        Where = "${home}/mnt/gphotos/personal";

        Options = [
          "_netdev"
          "poll-interval=30m"
        ];
      };
    };
  };
}

{ config
, pkgs
, ...
}:
let
  home = config.home.homeDirectory;
in
{
  home.packages = [
    pkgs.sshfs
    pkgs.rclone
  ];

  home.persistence."/persist${config.home.homeDirectory}".directories = [ "etc/rclone" ];

  systemd.user.tmpfiles.rules = [
    "d ${home}/mnt 755 - - - -"
    "d ${home}/mnt/gdrive 755 - - - -"
    "d ${home}/mnt/gdrive/appstate 755 - - - -"
    "d ${home}/mnt/gdrive/personal 755 - - - -"
    "d ${home}/mnt/ssh 755 - - - -"
    # "L+ ${home}/audio/library/lossless - - - - ${home}/mnt/ssh/spinoza.7596ff.com_raid/somasis/audio/library/lossless"
    # "L+ ${home}/audio/source - - - - ${home}/mnt/ssh/spinoza.7596ff.com_raid/somasis/audio/source"
    "L+ ${home}/vault - - - - ${home}/mnt/ssh/spinoza.7596ff.com_raid/somasis/backup/vault"
  ];

  # TODO This really ought to be templated.
  systemd.user.mounts = {
    "home-somasis-mnt-ssh-lacan.somas.is" = {
      Install.WantedBy = [ "default.target" ];
      Unit.After = [ "tunnel@lacan.somas.is.service" ];
      Unit.Requires = [ "tunnel@lacan.somas.is.service" ];
      Mount.Type = "fuse.sshfs";
      Mount.Options = [
        "compression=yes"
        "dir_cache=yes"
        "idmap=user"
        "max_conns=4"
        "transform_symlinks"
      ];
      Mount.What = "somasis@lacan.somas.is:/";
      Mount.Where = "${home}/mnt/ssh/lacan.somas.is";
    };

    "home-somasis-mnt-ssh-spinoza.7596ff.com" = {
      Install.WantedBy = [ "default.target" ];
      Unit.After = [ "tunnel@spinoza.7596ff.com.service" ];
      Unit.Requires = [ "tunnel@spinoza.7596ff.com.service" ];
      Mount.Type = "fuse.sshfs";
      Mount.Options = [
        "compression=yes"
        "dir_cache=yes"
        "idmap=user"
        "max_conns=4"
        "transform_symlinks"
      ];
      Mount.What = "somasis@spinoza.7596ff.com:/";
      Mount.Where = "${home}/mnt/ssh/spinoza.7596ff.com";
    };

    "home-somasis-mnt-ssh-spinoza.7596ff.com_raid" = {
      Install.WantedBy = [ "default.target" ];
      Unit.After = [ "tunnel@spinoza.7596ff.com.service" ];
      Unit.Requires = [ "tunnel@spinoza.7596ff.com.service" ];
      Mount.Type = "fuse.sshfs";
      Mount.Options = [
        "compression=yes"
        "dir_cache=yes"
        "idmap=user"
        "max_conns=4"
        "transform_symlinks"
      ];
      Mount.What = "somasis@spinoza.7596ff.com:/mnt/raid";
      Mount.Where = "${home}/mnt/ssh/spinoza.7596ff.com_raid";
    };

    "home-somasis-mnt-ssh-genesis.whatbox.ca" = {
      Install.WantedBy = [ "default.target" ];
      Unit.After = [ "tunnel@genesis.whatbox.ca.service" ];
      Unit.Requires = [ "tunnel@genesis.whatbox.ca.service" ];
      Mount.Type = "fuse.sshfs";
      Mount.Options = [
        "compression=yes"
        "dir_cache=yes"
        "idmap=user"
        "max_conns=4"
        "transform_symlinks"
      ];
      Mount.What = "somasis@genesis.whatbox.ca:";
      Mount.Where = "${home}/mnt/ssh/genesis.whatbox.ca";
    };
  };

  # TODO rclone _does_ support being used via mount(8) or a systemd.mount, but
  #      NixOS's rclone package doesn't expose it and I can't be bothered to fix it.
  #      <https://rclone.org/commands/rclone_mount/#rclone-as-unix-mount-helper>
  systemd.user.services = {
    "rclone-gdrive-personal" = {
      Unit.Description = "Mount Google Drive (personal) with rclone";
      Service.Type = "simple";
      Service.ExecStartPre = [ "${pkgs.networkmanager}/bin/nm-online -q" ];
      Service.ExecStart = ''
        ${pkgs.rclone}/bin/rclone mount gdrive-personal: ${home}/mnt/gdrive/personal --poll-interval 30m --vfs-cache-mode writes
      '';
      Service.Restart = "on-failure";
      Service.RestartSec = 30;
      Unit.PartOf = [ "default.target" ];
      Install.WantedBy = [ "default.target" ];
    };
    "rclone-gdrive-appstate" = {
      Unit.Description = "Mount Google Drive (appstate) with rclone";
      Service.Type = "simple";
      Service.ExecStartPre = [ "${pkgs.networkmanager}/bin/nm-online -q" ];
      Service.ExecStart = ''
        ${pkgs.rclone}/bin/rclone mount gdrive-appstate: ${home}/mnt/gdrive/appstate --poll-interval 30m --vfs-cache-mode writes
      '';
      Service.Restart = "on-failure";
      Service.RestartSec = 30;
      Unit.PartOf = [ "default.target" ];
      Install.WantedBy = [ "default.target" ];
    };
  };
}

{ config
, pkgs
, lib
, osConfig
, ...
}:
let
  cacheOptions = [
    "vfs-cache-mode=full"
    "vfs-cache-max-size=2G"

    "vfs-read-ahead=128Mi"
    "buffer-size=8Mi"

    "vfs-fast-fingerprint"
    # "write-back-cache"
  ];
in
{
  persist.directories = [{
    method = "bindfs";
    directory = config.lib.somasis.xdgConfigDir "rclone";
  }];
  cache.directories = [{
    method = "symlink";
    directory = config.lib.somasis.xdgCacheDir "rclone";
  }];

  programs.rclone = {
    enable = true;

    extraOptions =
      [ ]
      ++ [ "--default-time" "1970-01-01T00:00:00Z" ]
      ++ [ "--fast-list" ]
      ++ [ "--human-readable" ]
      ++ [ "--use-mmap" ]
      ++ map (flag: "--${flag}") cacheOptions
    ;

    remotes =
      let
        sftp = target: extraAttrs:
          assert (lib.isString target && target != "");
          assert (lib.isAttrs extraAttrs);
          let
            targetParts = builtins.match "(.*@)?(.+)" target;

            host = builtins.elemAt targetParts 1;
            user = lib.removeSuffix "@" (builtins.elemAt targetParts 0);

            sshPkg =
              if lib.isDerivation config.programs.ssh.package then
                config.programs.ssh.package
              else
                osConfig.programs.ssh.package or pkgs.openssh
            ;
            sshExe = lib.getExe sshPkg;
          in
          assert (lib.isString host && builtins.stringLength host > 0);
          {
            type = "sftp";

            # key_file = "${config.xdg.configHome}/ssh/id_ed25519";
            # known_hosts_file = config.programs.ssh.userKnownHostsFile;

            # This makes rclone not use its internal ssh library at all,
            # which reduces the potential of ssh-related issues.
            # inherit host user;
            ssh = "${sshExe} ${target}";
          } // extraAttrs
        ;

      in
      {
        "somasis@spinoza.7596ff.com" = sftp "somasis@spinoza.7596ff.com" { };
        "somasis@lacan.somas.is" = sftp "somasis@lacan.somas.is" { };
        "somasis@genesis.whatbox.ca" = sftp "somasis@genesis.whatbox.ca" { };

        gdrive-appstate = {
          type = "drive";
          scope = "drive";
          drive-export-formats = [ "docx" "xlsx" "pptx" "svg" ];
          poll-interval = "1m";
        };

        gdrive-personal = {
          type = "drive";
          scope = "drive";
          drive-export-formats = [ "docx" "xlsx" "pptx" "svg" ];
          poll-interval = "1m";
        };

        gphotos-personal = {
          type = "google photos";
          include_archived = true;
        };
      };
  };

  services.rclone = {
    enable = true;

    mounts = {
      spinoza = {
        remote = "somasis@spinoza.7596ff.com";
        what = "";
        where = "${config.home.homeDirectory}/mnt/sftp/spinoza.7596ff.com";
        # options = defaultOptions;
      };

      spinoza-raid = {
        remote = "somasis@spinoza.7596ff.com";
        what = "/mnt/raid/somasis";
        where = "${config.home.homeDirectory}/mnt/sftp/spinoza.7596ff.com_raid";
        # options = defaultOptions;
      };

      whatbox = {
        remote = "somasis@genesis.whatbox.ca";
        what = "";
        where = "${config.home.homeDirectory}/mnt/sftp/genesis.whatbox.ca";
        # options = defaultOptions;
      };

      gdrive-appstate = rec {
        remote = "gdrive-appstate";
        what = "";
        where = "${config.home.homeDirectory}/mnt/gdrive/appstate";

        # options = defaultOptions ++ [ "cache-dir=${config.xdg.cacheHome}/rclone/vfs-${remote}" ];
      };

      gdrive-appstate-shared = rec {
        remote = "gdrive-appstate,shared_with_me";
        what = "";
        where = "${config.home.homeDirectory}/mnt/gdrive/appstate-shared";

        # options = defaultOptions ++ [ "cache-dir=${config.xdg.cacheHome}/rclone/vfs-${remote}" ];
      };

      gdrive-personal = rec {
        remote = "gdrive-personal";
        what = "";
        where = "${config.home.homeDirectory}/mnt/gdrive/personal";

        # options = defaultOptions ++ [ "cache-dir=${config.xdg.cacheHome}/rclone/vfs-${remote}" ];
      };

      gdrive-personal-shared = rec {
        remote = "gdrive-personal,shared_with_me";
        what = "";
        where = "${config.home.homeDirectory}/mnt/gdrive/personal-shared";

        # options = defaultOptions ++ [ "cache-dir=${config.xdg.cacheHome}/rclone/vfs-${remote}" ];
      };

      gphotos-personal = {
        remote = "gphotos-personal";
        what = "";
        where = "${config.home.homeDirectory}/mnt/gphotos/personal";

        # NOTE rclone says
        # > --vfs-cache-mode writes or full is recommended for this remote as it can't stream
        options = cacheOptions;
      };
    };
  };

  home.file."vault".source = lib.mkIf (osConfig.networking.fqdnOrHostName != "spinoza.7596ff.com")
    (config.lib.file.mkOutOfStoreSymlink "${config.services.rclone.mounts.spinoza-raid.where}/backup/vault")
  ;
}

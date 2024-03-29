{ config
, pkgs
, ...
}: {
  services.udisks2.enable = true;

  boot.supportedFilesystems = [ "vfat" "zfs" ];

  boot.swraid.enable = false;

  # Fix there not being enough space for some Nix builds
  boot.tmp.useTmpfs = true;

  fileSystems = {
    "/" = {
      device = "none";
      fsType = "tmpfs";
      options = [ "mode=755" ];
    };

    "/home" = {
      device = "none";
      fsType = "tmpfs";
      neededForBoot = true;
      options = [
        "mode=755"
        # NOTE: Limit /home to 512mb of memory. I don't want to accidentally lock up
        #       the machine by extracting stuff to /home.
        # "size=512m"
      ];
    };

    "/nix" = {
      device = "${config.networking.fqdnOrHostName}/nixos/root/nix";
      fsType = "zfs";
      neededForBoot = true;
      options = [ "x-gvfs-hide" ];
    };

    "/persist" = {
      device = "${config.networking.fqdnOrHostName}/nixos/data/persist";
      fsType = "zfs";
      neededForBoot = true;
      options = [ "x-gvfs-hide" ];
    };

    "/cache" = {
      device = "${config.networking.fqdnOrHostName}/nixos/root/cache";
      fsType = "zfs";
      neededForBoot = true;
      options = [ "x-gvfs-hide" ];
    };

    "/log" = {
      device = "${config.networking.fqdnOrHostName}/nixos/root/log";
      fsType = "zfs";
      neededForBoot = true;
      options = [ "x-gvfs-hide" ];
    };
  };

  boot.zfs.requestEncryptionCredentials = [ "${config.networking.fqdnOrHostName}/nixos" ];

  # Restrict the ZFS ARC cache to 8GB.
  boot.extraModprobeConfig = ''
    options zfs zfs_arc_max=${toString (1024000000 * 8)}
  '';

  # <https://nixos.org/manual/nixos/unstable/#sec-zfs-state>
  cache.files = [ "/etc/zfs/zpool.cache" ];

  programs.fuse.userAllowOther = true;

  services.zfs = {
    trim.enable = true;

    autoScrub = {
      enable = true;
      pools = [ config.networking.fqdnOrHostName ];

      # Scrub on the first Sunday of each month at 8am.
      interval = "Sun *-*-01..07 08:00:00";
    };

    autoSnapshot = {
      enable = true;
      monthly = 3;
      weekly = 4;

      # -k: Keep empty snapshots.
      # -p: Create snapshots in parallel.
      # -u: Use UTC for snapshot naming to avoid possible jumps due to timezone changes, DST, etc.
      flags = "-p -u";
    };
  };

  # Only scrub when on AC power.
  systemd.timers.zfs-scrub.unitConfig.ConditionACPower = true;

  zramSwap.enable = true;
}

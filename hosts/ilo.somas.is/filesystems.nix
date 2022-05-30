{ config
, ...
}: {
  boot.supportedFilesystems = [
    "vfat"
    "zfs"
  ];

  fileSystems = {
    "/" = {
      device = "none";
      fsType = "tmpfs";
      options = [ "mode=755" ];
    };

    "/boot" = {
      device = "/dev/disk/by-id/nvme-WDS100T1X0E-00AFY0_2045A0800564-part1";
      fsType = "vfat";
      neededForBoot = true;
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
      device = "${config.networking.fqdn}/nixos/root/nix";
      fsType = "zfs";
      neededForBoot = true;
      options = [ "x-gvfs-hide" ];
    };

    "/persist" = {
      device = "${config.networking.fqdn}/nixos/data/persist";
      fsType = "zfs";
      neededForBoot = true;
      options = [ "x-gvfs-hide" ];
    };

    "/cache" = {
      device = "${config.networking.fqdn}/nixos/root/cache";
      fsType = "zfs";
      neededForBoot = true;
      options = [ "x-gvfs-hide" ];
    };

    "/log" = {
      device = "${config.networking.fqdn}/nixos/root/log";
      fsType = "zfs";
      neededForBoot = true;
      options = [ "x-gvfs-hide" ];
    };
  };

  boot.zfs.requestEncryptionCredentials = [ "${config.networking.fqdn}/nixos" ];

  # Restrict the ZFS ARC cache to 8GB.
  boot.extraModprobeConfig = ''
    options zfs zfs_arc_max=${toString (1024000000 * 8)}
  '';

  programs.fuse.userAllowOther = true;

  services.zfs = {
    trim.enable = true;

    autoScrub = {
      enable = true;
      pools = [ "${config.networking.fqdn}" ];
      interval = "Sun, 05:00";
    };

    autoSnapshot = {
      enable = true;
      monthly = 3;
      weekly = 4;

      # Use UTC for snapshot naming to avoid possible jumps due to timezone changes, DST, etc.
      flags = "-k -p --utc";
    };
  };

  zramSwap.enable = true;
}

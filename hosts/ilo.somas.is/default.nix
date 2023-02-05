{ pkgs
, lib
, config
, ...
}: {
  imports = [
    ./hardware
    ./networking
    ./hardware-configuration.nix

    ./backup.nix
    ./boot.nix
    ./console.nix
    ./filesystems.nix
    ./fonts.nix
    ./games.nix
    # ./harden.nix
    ./locale.nix
    ./nix.nix
    ./power.nix
    ./security.nix
    ./ssh.nix
    ./uptimed.nix
    ./users.nix
    ./wine.nix
  ];

  environment.persistence."/persist" = {
    hideMounts = true;
    directories = [
      "/etc/nixos"
    ];
  };

  environment.persistence."/cache" = {
    hideMounts = true;
    directories = [
      "/var/lib/systemd/timers"
      "/var/lib/systemd/timesync"
      "/var/lib/systemd/backlight"
    ];
    files = [
      "/var/lib/systemd/random-seed"
    ];
  };

  environment.persistence."/log" = {
    hideMounts = true;
    directories = [
      "/var/lib/systemd/catalog"
      "/var/lib/systemd/coredump"
      "/var/log/journal"
    ];
    files = [
      "/var/log/btmp"
      "/var/log/lastlog"
      "/var/log/wtmp"
    ];
  };

  hardware = {
    video.hidpi.enable = true;
    opengl.driSupport32Bit = true;
  };

  services.journald.console = "/dev/tty12";

  services.xserver.enable = true;

  documentation = {
    info.enable = false;
    doc.enable = false;
    dev.enable = true;
    nixos = {
      enable = true; # Provides `nixos-help`.
      includeAllModules = true;
    };

    man = {
      enable = true;
      generateCaches = true;
      man-db.enable = false;
      mandoc = {
        enable = true;
        # manPath = [ "share/man/tok" ];
      };
    };
  };

  programs.ssh.startAgent = true;

  programs.command-not-found.enable = false;
  environment = {
    defaultPackages = [ ];

    # Prevent any aliases from being set by default.
    shellAliases = lib.mkForce { };

    systemPackages = [
      # Necessary for `nixos-rebuild`'s git stuff
      pkgs.git

      pkgs.gparted
    ];

    variables = {
      XDG_CACHE_HOME = "\${HOME}/var/cache";
      XDG_CONFIG_HOME = "\${HOME}/etc";
      XDG_DATA_HOME = "\${HOME}/share";
      XDG_STATE_HOME = "\${HOME}/var/spool";
      XDG_BIN_HOME = "\${HOME}/local/bin";
      XDG_LIB_HOME = "\${HOME}/local/lib";
    };
  };

  # Force is required because services.xserver forces xdg.*.enable to true.
  xdg = lib.mkForce {
    autostart.enable = false;
    menus.enable = true;
    mime.enable = true; # TODO
    sounds.enable = false;
    portal.enable = false;
  };

  programs.bash = {
    enableCompletion = true;
    enableLsColors = false;
  };

  # services.gvfs.enable = lib.mkForce false;
  programs.dconf.enable = true;

  # TODO: Remove boot.zfs.enableUnstable when pkgs.linuxKernel.packages.linux_6_0 is compatible
  boot.kernelPackages = config.boot.zfs.package.latestCompatibleLinuxPackages;
  boot.zfs.enableUnstable = true;

  services.udisks2.enable = true;

  # TODO remove
  nixpkgs.config.permittedInsecurePackages = [
    "imagemagick-6.9.12-68"
  ];

  system.stateVersion = "22.11";

  # services.xserver.desktopManager = {
  #   plasma5 = {
  #     enable = false;
  #     useQtScaling = true;
  #     supportDDC = true;
  #   };
  #   cinnamon.enable = true;
  # };

  # services.xserver.displayManager.gdm.enable = true;
  # services.xserver.desktopManager.gnome.enable = true;
  # services.gnome = {
  #   core-utilities.enable = false;
  #   tracker.enable = false;
  #   tracker-miners.enable = false;
  # };
}

{ config
, pkgs
, lib
, ...
}:
{
  # Silent boot
  boot.initrd.verbose = false;
  boot.consoleLogLevel = 0;
  boot.kernelParams = [
    "quiet"
    "udev.log_level=3"
  ];

  boot.loader = {
    efi.canTouchEfiVariables = true;
    systemd-boot = {
      enable = true;
      editor = false;

      configurationLimit = 50;

      netbootxyz.enable = true;

      # TODO: NixOS installer image accessible from bootloader?
      # extraEntries."nixos-installer.conf" = ''
      #   title NixOS Installer
      #   efi /EFI/nixos-installer/memdisk.efi
      # '';

      # extraFiles = {
      #   "EFI/nixos-installer/nixos-installer.iso" = nixosInstaller;
      #   "EFI/nixos-installer/memdisk.efi" = "${pkgs.syslinux}/share/memdisk";
      # };
    };
    timeout = 0;
  };

  boot.initrd.systemd = {
    # NOTE: Necessary for ZFS password prompting via plymouth
    #       <https://github.com/NixOS/nixpkgs/issues/44965>
    enable = true;

    storePaths = [
      pkgs.busybox
      pkgs.dropbear
    ] ++ lib.optionals config.hardware.bluetooth.enable [ config.hardware.bluetooth.package ]
    ;
  };

  boot.plymouth = {
    enable = true;
    extraConfig = ''
      DeviceScale=1
    '';
    font = "${pkgs.iosevka-bin}/share/fonts/truetype/iosevka-regular.ttc";
  };

  environment.persistence."/log".files = [ "/var/log/X.0.log" ];

  services.xserver = {
    enable = true;
    tty = 1;
    displayManager.startx.enable = true;

    # displayManager.lightdm = {
    #   enable = true;

    #   background = "#000000";

    #   greeters = {
    #     gtk = {
    #       cursorTheme = {
    #         package = pkgs.hackneyed;
    #         name = "Hackneyed";
    #         size = 24;
    #       };
    #       iconTheme = {
    #         name = "Papirus";
    #         package = pkgs.papirus-icon-theme;
    #       };
    #       theme = {
    #         name = "Arc-Darker";
    #         package = pkgs.arc-theme;
    #       };
    #     };
    #   };
    # };
  };

  services.greetd = {
    enable = true;
    package = pkgs.greetd.tuigreet;
    restart = false;

    vt = 1;
    settings = {
      default_session.command = ''
        ${pkgs.greetd.tuigreet}/bin/tuigreet -c startx
      '';

      initial_session = {
        user = "somasis";
        command = "startx";
      };
    };
  };

  services.getty = {
    greetingLine = ''o kama pona tawa ${config.networking.fqdn}.'';
  };

  boot.kernel.sysctl."kernel.sysrq" = 22;
}

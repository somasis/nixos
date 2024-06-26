{ config
, pkgs
, lib
, ...
}: {
  fileSystems."/boot" = {
    device = "/dev/disk/by-id/nvme-WDS100T1X0E-00AFY0_2045A0800564-part1";
    fsType = "vfat";
    neededForBoot = true;
  };

  console.earlySetup = true;

  boot = {
    loader = {
      efi.canTouchEfiVariables = true;
      systemd-boot = {
        enable = true;
        editor = false;
        configurationLimit = 25;

        memtest86.enable = true;
        netbootxyz.enable = true;
      };

      timeout = 0;
    };

    # Silent boot.
    consoleLogLevel = 3;
    kernelParams = [ "quiet" "udev.log_level=3" ];

    extraModprobeConfig = ''
      options i915 enable_fbc=1
    '';

    initrd = {
      availableKernelModules = [ "i915" ];

      verbose = false;

      # NOTE: Necessary for ZFS password prompting via plymouth
      #       <https://github.com/NixOS/nixpkgs/issues/44965>
      systemd = {
        enable = true;

        storePaths = [
          pkgs.busybox
          pkgs.dropbear
        ] ++ lib.optional config.hardware.bluetooth.enable config.hardware.bluetooth.package
        ;
      };
    };

    # Tweak allowed sysrq key actions
    # <https://docs.kernel.org/admin-guide/sysrq.html>
    kernel.sysctl."kernel.sysrq" = builtins.foldl' (x: y: x + y) 0 [
      4 # enable keyboard controls
      16 # enable filesystem syncing
      32 # enable remounting filesystems read-only
      64 # enable signalling processes
      128 # enable reboot/poweroff
      256 # enable renicing all realtime tasks
    ];

    plymouth = {
      enable = true;
      themePackages = [ pkgs.nixos-bgrt-plymouth ];
      theme = "nixos-bgrt";

      extraConfig = ''
        DeviceScale=1
      '';
      # font = "${pkgs.iosevka-bin}/share/fonts/truetype/Iosevka-Regular.ttc";
      font = "${pkgs.noto-fonts}/share/fonts/noto/NotoSans[wdth,wght].ttf";
    };
  };

  services = {
    xserver = {
      enable = true;
      tty = 1;

      displayManager.startx.enable = true;
    };

    greetd = {
      enable = true;
      package = pkgs.greetd.tuigreet;
      restart = false;

      vt = 1;

      settings =
        # Log startx to systemd journal.
        let
          startx =
            pkgs.writeShellScript "startx" ''
              exec \
                  ${config.systemd.package}/bin/systemd-cat \
                      --identifier=startx \
                      --stderr-priority=err \
                      ${pkgs.xorg.xinit}/bin/startx "$@" -- \
                          -keeptty \
                          -logfile >(
                              ${pkgs.gnused}/bin/sed -E 's/^\[ +[0-9]+\.[0-9]+\] //' \
                                  | ${config.systemd.package}/bin/systemd-cat -t Xorg --level-prefix=false
                          ) \
                          -logverbose 7 \
                          -verbose 0
            '';
        in
        rec
        {
          initial_session = {
            user = builtins.head (builtins.attrNames (
              lib.filterAttrs (_: v: v.isNormalUser) config.users.users
            ));

            command = startx;
          };

          default_session.command = ''
            ${pkgs.greetd.tuigreet}/bin/tuigreet -c ${initial_session.command}
          '';
        };
    };

    getty.greetingLine = "o kama pona tawa ${config.networking.fqdnOrHostName}.";
  };
}

{ lib
, pkgs
, config
, ...
}:
let
  inherit (config.lib.somasis) floatToInt;

  monitor."${config.networking.fqdnOrHostName}" = {
    fingerprint = "00ffffffffffff0009e55f0900000000171d0104a51c137803de50a3544c99260f505400000001010101010101010101010101010101115cd01881e02d50302036001dbe1000001aa749d01881e02d50302036001dbe1000001a000000fe00424f452043510a202020202020000000fe004e4531333546424d2d4e34310a00fb";
    mode = "2256x1504";
    dpi = floatToInt (96 * 1.5);
  };
in
{
  services.autorandr = {
    enable = true;
    ignoreLid = true;

    defaultTarget = config.networking.fqdnOrHostName;
    profiles = {
      "${config.networking.fqdnOrHostName}" = {
        fingerprint.eDP-1 = monitor."${config.networking.fqdnOrHostName}".fingerprint;
        config."eDP-1" = {
          inherit (monitor."${config.networking.fqdnOrHostName}") dpi mode;
          primary = true;
          position = "0x0";
        };
      };
    };

    hooks = {
      postswitch.notify = ''
        ${pkgs.libnotify}/bin/notify-send \
            -a autorandr \
            -i preferences-desktop-display \
            -u low \
            'autorandr' \
            "Switched to profile '$AUTORANDR_CURRENT_PROFILE'."
      '';

      postswitch.dpi = ''
        dpi=$(${pkgs.gnused}/bin/sed '/^dpi/!d; s/^dpi *//; q' "$AUTORANDR_PROFILE_FOLDER/config")
        printf 'Xft.dpi: %s\n' "$dpi" | ${pkgs.xorg.xrdb}/bin/xrdb -merge
      '';
    };
  };


  systemd.user.services = {
    # autorandr = {
    #   Unit.PartOf = lib.mkForce [ "graphical-session-pre.target" ];
    #   Unit.After = lib.mkForce [ ];
    #   Install.WantedBy = lib.mkForce [ "graphical-session-pre.target" ];
    # };

    xiccd = lib.mkIf config.services.colord.enable {
      description = pkgs.xiccd.meta.description;
      script = "${pkgs.xiccd}/bin/xiccd";

      after = [ "dbus.service" ];
      partOf = [ "graphical-session.target" ];
      requires = [ "dbus.service" ];
      wantedBy = [ "graphical-session.target" ];
    };
  };

  # <https://www.notebookcheck.net/Framework-Laptop-13-5-Review-If-Microsoft-Made-A-Repairable-Surface-Laptop-This-Would-Be-It.551850.0.html>
  # Notebookcheck's calibration file for the monitor used by the Framework 11th gen, the BOE CQ NE135FBM-N41
  # xdg.dataFile = {
  #   # "share/icc/BOE CQ NE135FBM-N41.icc".source = pkgs.fetchurl {
  #   #   url = "https://www.notebookcheck.net/uploads/tx_nbc2/BOE_CQ_______NE135FBM_N41.icm";
  #   #   hash = "sha256-Sul8UxNABeK8pmJcjUuIbr24OLoM6E/mHi/qf+wJETY=";
  #   # };

  #   # <https://community.frame.work/t/display-accuracy-and-calibration/22381>
  #   # <https://www.mediafire.com/file/34tvr50khoe1ayj/NE135FBM-N41_%25232_2022-09-09_08-01_2.2_F-S_XYZLUT%252BMTX.icc/file>
  #   "share/icc/NE135FBM-N41 #2 2022-09-09 08-01 2.2 F-S XYZLUT+MTX.icc".source = ./display-BOE-CQ-NE135FBM-N41.icc;
  # };

  # TODO(?): Is this still needed? I used acpid for triggering
  #          autorandr on lid events when using my external monitors.
  services.acpid = {
    enable = true;
    lidEventCommands = ''
      ${pkgs.autorandr}/bin/autorandr --batch -c
    '';
  };

  services.xserver = {
    dpi = monitor."${config.networking.fqdnOrHostName}".dpi;
    upscaleDefaultCursor = true;
  };

  services.colord.enable = true;
  persist.directories = [{ user = "colord"; group = "colord"; directory = "/var/lib/colord"; }];
}

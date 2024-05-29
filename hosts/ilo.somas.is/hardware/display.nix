{ lib
, pkgs
, config
, ...
}:
let
  inherit (config.lib.somasis) floatToInt;

  monitor = {
    internal = {
      fingerprint = "00ffffffffffff0009e55f0900000000171d0104a51c137803de50a3544c99260f505400000001010101010101010101010101010101115cd01881e02d50302036001dbe1000001aa749d01881e02d50302036001dbe1000001a000000fe00424f452043510a202020202020000000fe004e4531333546424d2d4e34310a00fb";
      mode = "2256x1504";
      dpi = floatToInt (96 * 1.5);
      rate = "60.00";
    };

    tv = {
      fingerprint = "00ffffffffffff00593a331000000000011d0103806e3e782a626dad4f48aa250c474a254e00d1c0010101010101010101010101010104740030f2705a80b0588a0048684200001e023a801871382d40582c450048684200001e000000fc00563430352d47390a2020202020000000fd00174c0f8c3c000a202020202020012202035771575d645f011f10140513042022444b12160307111502066229097f07150750570600830f00006d030c003000383c200060010304e200ffeb0146d0004447439c3f1faae305e000e70e606165666a6be3060f0100000000000000000000000000000000000000000000000000000000000000000000000000000000a2";
      mode = "1920x1080";
      dpi = 96;
    };
  };
in
{
  services = {
    autorandr = {
      enable = true;

      ignoreLid = true;

      # Match exclusively based on the fingerprint rather than the display name.
      # The EDID can change based on the location that an expansion port ends up on the USB bus.
      matchEdid = true;

      defaultTarget = config.networking.fqdnOrHostName;

      profiles = {
        "${config.networking.fqdnOrHostName}" = {
          fingerprint."eDP-1" = monitor.internal.fingerprint;

          config = {
            "eDP-1" = {
              enable = true;
              crtc = 0;
              primary = true;
              inherit (monitor.internal) dpi mode rate;
            };
          }
          // lib.genAttrs [ "DP-1" "DP-2" "DP-3" "DP-4" ] (_: { enable = false; })
          ;
        };

        "${config.networking.fqdnOrHostName}:tv" = {
          fingerprint."eDP-1" = monitor.internal.fingerprint;
          fingerprint."DP-3" = monitor.tv.fingerprint;

          config = {
            "DP-3" = {
              enable = true;
              crtc = 0;
              primary = true;
              inherit (monitor.tv) dpi mode;
            };
          }
          // lib.genAttrs [ "eDP-1" "DP-1" "DP-2" "DP-4" ] (_: { enable = false; })
          ;
        };
      };

      hooks = {
        preswitch.notify = ''
          ${lib.toShellVar "default_profile" config.services.autorandr.defaultTarget}
          [[ "$default_profile" != "$AUTORANDR_CURRENT_PROFILE" ]] || exit

          notification_file="''${XDG_RUNTIME_DIR:=/run/user/$(id -un)}/autorandr.notification"

          ${pkgs.libnotify}/bin/notify-send \
              --print-id \
              -a autorandr \
              -i preferences-desktop-display \
              -u low \
              -e \
              "Switching to ''${AUTORANDR_CURRENT_PROFILE@Q}..." \
              > "$notification_file"
        '';

        postswitch.notify = ''
          ${lib.toShellVar "default_profile" config.services.autorandr.defaultTarget}
          [[ "$default_profile" != "$AUTORANDR_CURRENT_PROFILE" ]] || exit

          notification_file="''${XDG_RUNTIME_DIR:=/run/user/$(id -un)}/autorandr.notification"
          notification_id=

          if [[ -s "$notification_file" ]]; then
              notification_id=$(<"$notification_file")
          fi

          ${pkgs.libnotify}/bin/notify-send \
              ''${notification_id:+--replace-id="$notification_id"} \
              -a autorandr \
              -i preferences-desktop-display \
              -u low \
              -e \
              'Display profile changed' \
              "Switched to profile ''${AUTORANDR_CURRENT_PROFILE@Q}."
        '';

        postswitch.dpi = ''
          ${lib.toShellVar "PATH" (lib.makeBinPath [ pkgs.xorg.xrdb pkgs.gnused ])}

          dpi=$(sed '/^dpi/!d; s/^dpi *//; q' "$AUTORANDR_PROFILE_FOLDER/config" 2>/dev/null)
          [[ -n "$dpi" ]] || dpi=96

          xrdb -merge <<< "Xft.dpi: $dpi"
        '';
      };
    };

    # NOTE Trigger autorandr on lid-close/lid-open events; pkgs.autorandr and
    #      services.autorandr does not include autorandr-lid-listener.service,
    #      but furthermore, the implementation of that service is really gross
    #      anyway, so it's better to use acpid.
    #      <https://github.com/phillipberndt/autorandr/issues/333#issuecomment-1916059091>
    acpid = {
      enable = true;
      lidEventCommands = ''
        ${pkgs.systemd}/bin/systemctl start autorandr.service
      '';
    };

    xserver = {
      inherit (monitor.internal) dpi;
      upscaleDefaultCursor = true;
    };

    colord.enable = true;
  };

  systemd = {
    user.services.xiccd = lib.mkIf config.services.colord.enable {
      inherit (pkgs.xiccd.meta) description;
      script = lib.getExe pkgs.xiccd;

      after = [ "dbus.service" ];
      partOf = [ "graphical-session.target" ];
      requires = [ "dbus.service" ];
      wantedBy = [ "graphical-session.target" ];
    };

    services.autorandr = {
      startLimitBurst = lib.mkForce 2;
      startLimitIntervalSec = lib.mkForce 5;
    };

    # colord looks in /var/lib/colord/icc for calibration profiles.
    services.colord.preStart =
      let
        # Notebookcheck's calibration file for the monitor used by the Framework 13, the BOE CQ NE135FBM-N41.
        # <https://www.notebookcheck.net/Framework-Laptop-13-5-Review-If-Microsoft-Made-A-Repairable-Surface-Laptop-This-Would-Be-It.551850.0.html>
        notebookcheckICC = pkgs.fetchurl {
          url = "https://www.notebookcheck.net/uploads/tx_nbc2/BOE_CQ_______NE135FBM_N41.icm";
          hash = "sha256-Sul8UxNABeK8pmJcjUuIbr24OLoM6E/mHi/qf+wJETY=";
          curlOptsList = [ "--user-agent" "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) QtWebEngine/6.6.3 Chrome/112.0.5615.213 Safari/537.36" ];
        };

        # <https://community.frame.work/t/display-accuracy-and-calibration/22381>
        uweICC = pkgs.fetchMediaFire {
          url = "https://www.mediafire.com/file/34tvr50khoe1ayj/NE135FBM-N41_%25232_2022-09-09_08-01_2.2_F-S_XYZLUT%252BMTX.icc";
          hash = "sha256-n77S2avYTPXlmaQd+FA2trjfoXeNQqxW0+P5ehw+jGc=";
        };

        profiles = [ notebookcheckICC uweICC ];

        installedProfilesDir = "/var/lib/colord/icc";
      in
      ''
        ${lib.toShellVar "installed_profiles_dir" installedProfilesDir}
        ${lib.toShellVar "profiles" profiles}

        for profile in "''${profiles[@]}"; do
            profile_name=$(basename "$profile")
            if [ -e "$installed_profiles_dir/$profile_name" ]; then
                echo "profile '$profile_name' is already installed" >&2
            else
                ln -vsf "$profile" "$installed_profiles_dir"/"$profile_name"
            fi
        done
      ''
    ;
  };

  persist.directories = [{ user = "colord"; group = "colord"; directory = "/var/lib/colord"; }];
}

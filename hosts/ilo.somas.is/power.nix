{ config
, lib
, pkgs
, ...
}: {
  services.logind = {
    lidSwitch = "suspend";
    lidSwitchExternalPower = "lock";
    lidSwitchDocked = "ignore";

    powerKey = "suspend";
    powerKeyLongPress = "poweroff";

    extraConfig = ''
      PowerKeyIgnoreInhibited=yes
    '';
  };

  services.upower = {
    enable = true;
    criticalPowerAction = "PowerOff";

    percentageLow = 15;
    percentageCritical = 5;
    percentageAction = 0;
  };

  powerManagement.cpuFreqGovernor = "powersave";

  # Auto-tune with powertop on boot.
  powerManagement.powertop.enable = true;
  cache.directories = [ "/var/cache/powertop" ];
  log.directories = [ "/var/lib/upower" ];

  # Manage CPU temperature.
  services.thermald.enable = true;
  services.auto-cpufreq.enable = true; # they don't conflict, apparently

  # Manage battery life automatically.
  services.tlp.enable = false;

  # Automatically `nice` programs for better performance.
  services.ananicy = {
    enable = true;
    package = pkgs.ananicy-cpp;

    extraRules =
      [
        { name = "kitty"; type = "terminal"; }
        { name = ".kitty-wrapped"; type = "terminal"; }

        { name = "qutebrowser"; type = "web-browser"; }

        { name = "armcord"; type = "chat"; }
        { name = "Discord"; type = "chat"; }
        { name = ".Discord-wrapped"; type = "chat"; }

        { name = "kak"; type = "document-editor"; }
        { name = "zotero"; type = "document-viewer"; }
        { name = "zotero-bin"; type = "document-viewer"; }
        { name = "soffice"; type = "document-editor"; }

        { name = "slop"; type = "screenshotter"; }
        { name = "maim"; type = "screenshotter"; }

        { name = ".rclone-wrapped"; type = "file-sync"; }

        { name = "scantailor"; type = "LowLatency_RT"; }
        { name = ".scantailor-wrapped"; type = "LowLatency_RT"; }
      ]
      ++ map (name: { inherit name; type = "BG_CPUIO"; }) [
        "bindfs"
        "bwrap"
        "nix-daemon"

        "mbsync"

        # GeoClue
        "geoclue"
        ".geoclue-wrapped"

        "udisksd"

        "dbus-daemon"

        "iio-sensor-proxy"
        "localtimed"

        "systemd-logind"
        "systemd-resolved"
        "systemd-socket-proxyd"

        "listenbrainz-mpd"
        "mpDris2"
        ".mpDris2-wrapped"
        "..mpDris2-wrapped-wrapped" # ?
        "mpris-proxy"
        "mpdscribble"
        "mpd-discord-rpc"

        "clipmenud"
        ".clipmenud-wrapped"

        "pass_secret_service"
        ".pass_secret_service-wrapped"

        "systemd-wait"
        ".systemd-wait-wrapped"
      ]
      ++ map (name: { inherit name; type = "services"; }) [
        "fwupd"
        ".fwupd-wrapped"

        "usbguard-daemon"

        "goimapnotify"

        "upower"

        "xplugd"
        "colord"
        "xiccd"
      ]
      ++ map (name: { inherit name; type = "DEWM"; }) [
        "dunst"
        ".dunst-wrapped"

        "usbguard-notifier"
        "xss-lock"
        "xsecurelock"

        "clipnotify"

        "batsignal"
        "dunst"
        "fcitx5"
        "lemonbar"
        "stalonetray"
        "snixembed"
        "unclutter"

        "stw"

        "nmcli"

        # GeoClue
        "agent"
        ".agent-wrapped"

        "udiskie"
        ".udiskie-wrapped"

        # "xtitle"
        # "bspc"

        # "xclip"
        "dmenu"
      ]
      ++ map (name: { inherit name; type = "common-utility"; }) [
        "rwc"
        "snooze"

        "coreutils"

        "bash"

        "mpc"

        "rfkill"

        "pactl"
      ]
    ;
  };

  # ananicy spams the log constantly
  systemd.services.ananicy-cpp.serviceConfig.StandardOutput = "null";

  services.systemd-lock-handler.enable = true;

  systemd.shutdown."wine-kill" = pkgs.writeShellScript "wine-kill" ''
    ${pkgs.procps}/bin/pkill '^winedevice\.exe$' || :
    if [[ -n "$(${pkgs.procps}/bin/pgrep '^winedevice\.exe$')" ]]; then
        ${pkgs.procps}/bin/pkill -e -9 '^winedevice\.exe$' || :
    fi
    exit 0
  '';

  environment.etc = {
    "systemd/system-sleep/99-wake-xsecurelock".source =
      pkgs.writeShellScript "wake-xsecurelock" ''
        if [[ "$1" = "post" ]]; then ${pkgs.procps}/bin/pkill -x -USR2 xsecurelock || :; fi
        exit 0
      '';

    "systemd/system-sleep/00-log-power".source =
      let
        sleep-power-usage = pkgs.writeShellScript "sleep-power-usage" ''
          PATH=${lib.makeBinPath [ config.services.upower.package pkgs.gnugrep pkgs.jc pkgs.jq ]}

          device=$(upower -e | grep '/battery_')
          upower -i "$device" \
              | jc --upower \
              | jq -r '
                  .[]
                      | if .detail.present == true then
                          "\(.detail.type | split("") | ((.[0] | ascii_upcase) + (.[1:] | join("")))) \"\(.native_path)\" \(.detail.state):"
                              + " \((.detail.percentage))%"
                              + (if .detail.time_to_empty? != null then "; approximately \(.detail.time_to_empty) \(.detail.time_to_empty_unit) remaining if left on" else "" end)
                      else
                          halt
                      end
              '
        '';
      in

      pkgs.writeShellScript "log-power" ''
        PATH=${lib.makeBinPath [ config.systemd.package ]}

        if [[ "$1" = "pre" ]]; then
            systemd-cat -t "sleep-power-usage" ${sleep-power-usage} "$device" || :
        elif [[ "$1" = "post" ]]; then
            systemd-cat -t "sleep-power-usage" ${sleep-power-usage} "$device" || :
        fi

        exit 0
      '';
  };
}

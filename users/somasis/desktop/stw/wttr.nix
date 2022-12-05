{ pkgs, config, ... }:
let
  wttr = (pkgs.writeShellApplication {
    name = "wttr";

    runtimeInputs = [
      pkgs.curl
      pkgs.geoclue2-with-demo-agent
      pkgs.gnused
      pkgs.xe
      pkgs.coreutils
      pkgs.moreutils
      config.programs.jq.package
    ];

    text = ''
      PATH="${pkgs.geoclue2-with-demo-agent}/libexec/geoclue-2.0/demos:$PATH"

      c() { curl -Lf -H "Accept-Language: $lang" "$@"; }
      c_en() { lang=en c "$@"; }

      geoclue() {
          # We have to loop the agent because it seems that sometimes it doesn't actually
          # talk to the daemon successfully.
          t=0
          until geoclue=$(
              LC_ALL=C where-am-i \
                  -t 15 \
                  -a 4 \
                  2>/dev/null \
                  | sed -E \
                      -e '/(Latitude|Longitude)/!d' \
                      -e 's/(Latitude|Longitude):  *//' \
                      -e 's/\?$//' \
                      -e 's/0*$//' \
                  | xe -N2 printf '%s,%s\n'); do
              t=$(( t + 1 ))
              sleep 5

              # We suck, just give a fallback I guess
              [ "$t" -ge 10 ] && printf '@spinoza.7596ff.com\n' && return
          done

          printf '%s\n' "$geoclue"
      }

      update() {
          lang=''${LANG%%.*}
          lang=''${lang%%_*}

          # See what the auto-detected location was
          location=$(c_en "https://wttr.in/?format=%l\n&period=60" | jq -Rr @uri)

          # Ask geoclue, if wttr.in couldn't tell what our location was
          if [ "$location" = "not%20found" ]; then
              location=$(geoclue)

              # and then if THAT fails just use home I guess.
              case "$(c_en "https://wttr.in/$location?format=%l\n&period=60")" in
                  "not found"|"")
                      location="@spinoza.7596ff.com"
                      ;;
              esac
          fi

          temp=$(mktemp)
          c -o "$temp" "https://wttr.in/$location?2FTqnu"

          if [ -s "$temp" ]; then
              sed "1 s/$/ (fetched at $(date +'%I:%M %p'))/" "$temp" >"$d/forecast.txt"
              touch "$d/forecast.txt"
          else
              exit 1
          fi
          rm -f "$temp"
      }

      d="${config.xdg.cacheHome}"/wttr
      mkdir -p "$d"

      forecast_fetched=$(stat -c %Y "$d"/forecast.txt 2>/dev/null || echo 0)
      if ! [ -e "$d"/forecast.txt ] \
          || [ "$(( $(( "$(date +%s)" - 900 )) - forecast_fetched ))" -ge 900 ]; then
          # forecast is outdated if it's older than 15 minutes ago
          update
      fi

      exec cat "$d/forecast.txt"
    '';
  });
in
{
  home.packages = [ wttr ];

  systemd.user = {
    services.wttr = {
      Unit = {
        Description = "Update weather at the current location";
        StartLimitInterval = 60;

        PartOf = [ "stw.target" ];
        Requires = [ "geoclue-agent.service" ];
      };

      Install.WantedBy = [ "stw.target" ];

      Service = {
        Type = "oneshot";
        ExecStart = [ "${wttr}/bin/wttr" ];
        ExecStopPost = [ "-${pkgs.systemd}/bin/systemctl reload --user stw@wttr.service" ];
        StandardOutput = "null";
      }
      // (lib.optionalAttrs (nixosConfig.networking.networkmanager.enable) { ExecStartPre = [ "${pkgs.networkmanager}/bin/nm-online -q" ]; })
      ;
    };

    timers.wttr = {
      Unit.Description = "Refresh weather for the current location every hour";
      Install.WantedBy = [ "stw.target" ];
      Unit.PartOf = [ "stw.target" ];
      # Timer.OnCalendar = "0/2:00:00";
      Timer = {
        OnCalendar = "hourly";
        AccuracySec = "30m";
        RandomizedDelaySec = "5m";
        OnClockChange = true;
        OnTimezoneChange = true;
        Persistent = true;
      };
    };
  };

  somasis.chrome.widgets.stw = [
    {
      name = "wttr";

      text = {
        font = "monospace:style=heavy:size=10";
        color = config.xresources.properties."*darkForeground";
      };

      window = {
        opacity = 0;
        position = {
          x = 24;
          y = 72;
        };

        padding = 12;
      };

      update = 60;

      command = "${pkgs.coreutils}/bin/cat %C/wttr/forecast.txt";
    }
  ];
}

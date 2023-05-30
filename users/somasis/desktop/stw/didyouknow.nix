{ lib
, pkgs
, config
, ...
}: {
  somasis.chrome.stw = {
    enable = true;
    widgets = [{
      name = "didyouknow";

      text = {
        font = "monospace:style=heavy:size=10";
        color = config.xresources.properties."*darkForeground";
      };

      window = {
        color = config.xresources.properties."*darkBackground";
        opacity = 0.15;

        position = {
          x = 24;
          y = 72;
        };

        padding = 12;
      };

      update = 0;

      command = ''
        ${pkgs.coreutils}/bin/cat "$XDG_CACHE_HOME"/stw/didyouknow.txt
      '';
    }];
  };

  cache.files = [ "var/cache/stw/didyouknow.txt" ];

  systemd.user = {
    timers."didyouknow" = {
      Unit.Description = "Fetch Wikipedia's 'Did you know?' text for the current day, every day";
      Install.WantedBy = [ "stw@didyouknow.service" ];
      Unit.PartOf = [ "stw@didyouknow.service" ];
      Timer = {
        OnCalendar = "daily";
        RandomizedDelaySec = "0";
        Persistent = true;
      };
    };

    services."didyouknow" = {
      Unit.Description = "Fetch today's Wikipedia 'Did you know?' text";

      Service.Type = "oneshot";
      Service.Environment = [
        "PATH=${lib.makeBinPath [ pkgs.coreutils pkgs.curl pkgs.gnused pkgs.pandoc ]}"
      ];

      Service.ExecStart = [
        (builtins.toString (pkgs.writeShellScript "didyouknow" ''
          set -euo pipefail

          : "''${XDG_CACHE_HOME:=$HOME/var/cache}"
          mkdir -p "$XDG_CACHE_HOME/stw"

          dyk=$(${pkgs.curl}/bin/curl -fsL "https://en.wikipedia.org/wiki/Template:Did_you_know?action=raw")

          [ -n "$dyk" ] || exit 1

          exec > "$XDG_CACHE_HOME/stw/didyouknow.txt"

          wrapped=$(
              printf '%s\n' "$dyk" \
                  | sed -E \
                      -e '1,/^<!--Hooks-->/d' \
                      -e '/^<!--HooksEnd-->/,$ d' \
                      -e 's/\{\{-\?\}\}/?/' \
                  | pandoc -f mediawiki -t plain --wrap=preserve \
                  | sed -E \
                      -e 's/^-   //' \
                      -e '/^\.\.\. / s/$/\n/' \
                      -e 's/\([^)]+\W+pictured\)//' \
                      -e 's/\(pictured[^)]+\W+\)//' \
                      -e 's/\([^)]+\W+pictured[^)]+\W+\)//' \
                  | fold -s
          )

          printf "%s %$(( $(wc -L <<< "$wrapped") - 15 ))s\n\n%s\n" \
              "Did you know?" "$(date +'(for %Y-%m-%d)')" \
              "$wrapped"
        ''))
      ];
      Service.ExecStartPost = [ "-${pkgs.systemd}/bin/systemctl --user reload stw@didyouknow.service" ];
    };
  };
}

{ lib
, pkgs
, config
, osConfig
, ...
}:
let
  fixtext = pkgs.writeShellScriptBin "fixtext" ''
    sed -E \
        -e 's/\s+\(pictured\)/ /' \
        -e 's/\(pictured\)\s+/ /' \
        -e 's/\(pictured\)//' \
        -e 's/\([^)]+\W+pictured\)//' \
        -e 's/\(pictured[^)]+\W+\)//' \
        -e 's/\([^)]+\W+pictured[^)]+\W+\)//' \
        | tr -s '[[:blank:]]' \
        | sed -E -e 's/ ([!?,\.])$/\1/g'
  '';

  fetch-didyouknow = pkgs.writeShellScript "fetch-didyouknow" ''
    PATH=${lib.makeBinPath [ fixtext pkgs.coreutils pkgs.curl pkgs.gnused pkgs.pandoc pkgs.table pkgs.teip ]}:"$PATH"

    : "''${XDG_CACHE_HOME:=$HOME/var/cache}"
    dir="$XDG_CACHE_HOME/didyouknow"

    mkdir -p "$dir"

    curl() {
        command curl -Lf --no-progress-meter --compressed "$@"
    }

    didyouknow=$(
        curl \
            --get \
            -d 'action=parse' \
            -d 'format=json' \
            --data-urlencode 'page=Template:Did you know' \
            -d 'redirects=1' \
            -d 'prop=text' \
            -d 'section=2' \
            -d 'disableeditsection=1' \
            -d 'disabletoc=1' \
            -d 'formatversion=2' \
            'https://en.wikipedia.org/w/api.php'
    )

    featured=$(
        curl "https://api.wikimedia.org/feed/v1/wikipedia/en/featured/$(date +%Y/%m/%d)"
    )

    if [[ -z "$didyouknow" ]] || [[ -z "$featured" ]]; then
        exit 1
    fi

    onthisday=$(
        jq -r '
            .onthisday
              | sort_by(.year)
              | map(
                (.year | if . >= 0 then . else "\(. * -1) BC" end) as $year
                  | "\($year):\t\(.text)"
              )
            ' <<< "$featured" \
            | teip -d $'\t' -f2 -s -- fixtext \
            | table -R1 -o $'\t'
    )

    onthisday_width=$(cut -f1 <<<"$onthisday" | wc -L)
    onthisday_indent=$(
        i=0
        s=
        while [[ "$i" -lt "$(( onthisday_width + 1 ))" ]]; do
            s="$s "
            i=$(( i + 1 ))
        done
        printf '%s' "$s"
    )

    # Word wrap the second column.
    onthisday=$(
        # <https://stackoverflow.com/a/55206273>
        sed '
            :a
            /.\{80\}/s/\([^\n]\{1,79\}\) \([^\n]\+\)/\1\n'"$onthisday_indent"'\2/
            /\n/!bb
            P
            D
            :b
            ta
            ' <<< "$onthisday" \
            | tr '\t' ' '
    )

    aotd=$(
        jq -r '
            (.tfa.extract | if (. | length) >= 200 then "\(.[0:220] | rtrimstr(" "))..." else . end) as $extract
              | "\(.tfa.titles.normalized)\n\n\($extract)"
            ' <<< "$featured" \
            | fixtext
    )

    didyouknow=$(
        sed -E \
            -e '1,/^<!--Hooks-->/d' \
            -e '/^<!--HooksEnd-->/,$ d' \
            -e 's/\{\{-\?\}\}/?/' \
            -e "s/\`/'/g" \
            -e '/^\{\{.*\}\}$/d' \
            -e 's/\{\{|\}\}//g' \
            <<< "$didyouknow" \
            | pandoc -f html -t plain --wrap=preserve \
            | pandoc -f mediawiki -t plain --wrap=preserve \
            | sed -E \
                -e 's/^-   //' \
                -e '/^\.\.\. / s/$/\n/' \
            | fixtext
    )

    [ -n "$onthisday" ] || exit 1
    [ -n "$aotd" ] || exit 1
    [ -n "$didyouknow" ] || exit 1

    printf '%s in history...\n\n%s\n' "$(date +'%B %d')" "$onthisday" > "$dir"/onthisday.txt
    printf 'Article of the day: %s\n' "$(fold -s -w 79 <<<"$aotd")" > "$dir"/aotd.txt
    printf 'Did you know?\n\n%s\n' "$(fold -s -w 79 <<< "$didyouknow")" > "$dir"/didyouknow.txt
  '';

  didyouknow = pkgs.writeShellScriptBin "didyouknow" ''
    dir="''${XDG_CACHE_HOME:=$HOME/.cache}"/didyouknow

    for f in "$dir"/*.txt; do
        [ -e "$f" ] || {
            ${pkgs.systemd}/bin/systemctl --user start fetch-didyouknow.service
            break
        }
    done

    for f in "$dir"/*.txt; do
        cat "$f"
        printf '\n'
    done
  '';
in
{
  home.packages = [ didyouknow ];

  somasis.chrome.stw.widgets.didyouknow = {
    text = {
      font = "monospace:style=heavy:size=10";
      color = config.xresources.properties."*darkForeground";
    };

    window = {
      color = config.xresources.properties."*darkBackground";
      opacity = 0.25;

      position = {
        x = 24;
        y = 72;
      };

      padding = 12;
    };

    update = 0;

    command = ''
      cat "''${XDG_RUNTIME_DIR:=/run/user/$(id -u)}"/didyouknow/stw.txt
    '';
  };

  cache.directories = [ "var/cache/didyouknow" ];

  systemd.user = {
    timers.fetch-didyouknow = {
      Unit.Description = "Fetch Wikipedia's 'Did you know?' text for the current day, every day";
      Install.WantedBy = [ "default.target" ];
      Install.RequiredBy = [ "stw@didyouknow.service" ];
      Unit.PartOf = [ "default.target" "stw@didyouknow.service" ];
      Timer = {
        OnCalendar = "daily";
        OnStartupSec = 0;
        Persistent = true;
      };
    };

    timers.set-didyouknow = {
      Unit.Description = "Set the currently displaying 'Did you know?' widget text, every hour";
      Install.WantedBy = [ "default.target" ];
      Install.RequiredBy = [ "stw@didyouknow.service" ];
      Unit.PartOf = [ "default.target" "stw@didyouknow.service" ];
      Timer = {
        OnCalendar = "hourly";
        OnStartupSec = 0;
        Persistent = true;
      };
    };

    services.set-didyouknow = {
      Unit.Description = "Set the currently displaying 'Did you know?' widget text";

      Service = {
        Type = "oneshot";
        ExecStart = pkgs.writeShellScript "set-didyouknow" ''
          dir="''${XDG_CACHE_HOME:=$HOME/.cache}"/didyouknow
          runtime="''${XDG_RUNTIME_DIR:=/run/user/$(id -u)}"/didyouknow
          [ -d "$runtime" ] || mkdir "$runtime"
          for f in "$dir"/*.txt; do
              [ -e "$f" ] || {
                  ${pkgs.systemd}/bin/systemctl --user start fetch-didyouknow.service
                  break
              }
          done

          if [ $(( $(date +%H) % 2 )) -eq 0 ]; then
              file="$dir"/didyouknow.txt
          else
              file="$dir"/onthisday.txt
          fi

          ln -sf "$file" "$runtime"/stw.txt
        '';
        ExecStartPost = "-${pkgs.systemd}/bin/systemctl --user reload stw@didyouknow.service";
      };
    };
  };
}

{ lib
, pkgs
, config
, osConfig
, ...
}:
let
  fixtext = pkgs.writeShellScriptBin "fixtext" ''
    tr -s '[[:blank:]]' \
        | sed -E \
            -e 's/\s+\(pictured\)/ /' \
            -e 's/\(pictured\)\s+/ /' \
            -e 's/\(pictured\)//' \
            -e 's/\([^)]+\W+pictured\)//' \
            -e 's/\(pictured[^)]+\W+\)//' \
            -e 's/\([^)]+\W+pictured[^)]+\W+\)//' \
        | sed -E \
            -e "/ ' .* ' / {
                s/ ' / '/
                s/ ' /' /
            }" \
            -e '/ " .* " / {
                s/ " / "/
                s/ " /" /
            }' \
            -e 's/ ([!?,\.]) /\1 /g' \
            -e 's/ ([!?,\.])$/\1/g' \
        | tr -s '[[:blank:]]'
  '';

  fetch-didyouknow = pkgs.writeShellScript "fetch-didyouknow" ''
    PATH=${lib.makeBinPath [ fixtext pkgs.coreutils pkgs.curl pkgs.dateutils pkgs.gnused pkgs.pandoc pkgs.pup pkgs.table pkgs.teip ]}:"$PATH"

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
              )[]
            ' <<< "$featured" \
            | teip -d $'\t' -f2 -s -- fixtext \
            | {
                stdin=$(cat)
                lines=$(wc -l <<< "$stdin")
                [ "$lines" -gt 16 ] && stdin="$(head -n 16 <<< "$stdin")"$'\n\t'"[and $lines more...]"
                printf '%s\n' "$stdin"
            } \
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
            .tfa.extract as $extract
            | .tfa.titles.normalized as $title
            | "\($title)\n\n\($extract)"
            ' <<< "$featured" \
            | fixtext \
            | fmt
    )

    didyouknow=$(
        jq -re .parse.text <<< "$didyouknow" \
            | pup --charset UTF-8 'body > div > ul > li' \
            | pandoc -f html -t plain --wrap=none \
            | fixtext \
            | fmt -t \
            | sed 's/^[^\.]/ &/'
    )

    [ -n "$onthisday" ] || exit 1
    [ -n "$aotd" ] || exit 1
    [ -n "$didyouknow" ] || exit 1

    printf '%s in history...\n\n%s' "$(dateconv -f '%B %dth' now)" "$onthisday" > "$dir"/onthisday.txt
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

  services.stw.widgets.didyouknow = {
    text = {
      font = "monospace:style=heavy:size=10";
      color = config.theme.colors.darkForeground;
    };

    window = {
      color = config.theme.colors.darkBackground;
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

    services.fetch-didyouknow = {
      Unit.Description = "Fetch today's Wikipedia 'Did you know?' text";

      Service = {
        Type = "oneshot";
        ExecStartPre = lib.optional osConfig.networking.networkmanager.enable "${pkgs.networkmanager}/bin/nm-online -q";
        ExecStart = fetch-didyouknow;
      };
    };

    timers.set-didyouknow = {
      Unit.Description = "Set the currently displaying 'Did you know?' widget text, every hour";
      Install.WantedBy = [ "graphical-session.target" ];
      Install.RequiredBy = [ "stw@didyouknow.service" ];
      Unit.PartOf = [ "graphical-session.target" "stw@didyouknow.service" ];
      Timer = {
        OnCalendar = "hourly";
        OnStartupSec = 0;
        Persistent = true;
      };
    };

    services.set-didyouknow = {
      Unit.Description = "Cycle the currently displaying 'Did you know?' widget text";
      Install.WantedBy = [ "stw@didyouknow.service" ];

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

          current_file=$(basename "$(readlink "$runtime"/stw.txt)" .txt) || current_file=
          case "$current_file" in
              ""|aotd)    next_file="$dir"/onthisday.txt  ;;
              onthisday)  next_file="$dir"/didyouknow.txt ;;
              didyouknow) next_file="$dir"/aotd.txt       ;;
          esac

          ln -sf "$next_file" "$runtime"/stw.txt
        '';
        ExecStartPost = "-${pkgs.systemd}/bin/systemctl --user reload stw@didyouknow.service";
      };
    };
  };
}

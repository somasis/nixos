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

    if [[ -n "$didyouknow" ]]; then
        didyouknow=$(
            jq -re .parse.text <<< "$didyouknow" \
                | pup --charset UTF-8 'body > div > ul > li' \
                | pandoc -f html -t plain --wrap=none \
                | fixtext \
                | fmt -t \
                | sed 's/^[^\.]/ &/'
        )

        printf 'Did you know?\n\n%s\n' "$(fold -s -w 79 <<< "$didyouknow")" > "$dir"/didyouknow.txt
    else
        rm -f "$dir"/didyouknow.txt
    fi

    if [[ -n "$featured" ]]; then
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
                    [[ "$lines" -gt 16 ]] && stdin="$(head -n 16 <<< "$stdin")"$'\n\t'"[and $lines more...]"
                    printf '%s\n' "$stdin"
                } \
                | table -N YEAR,EVENT -R YEAR -d -o $'\t'
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
                | if $extract == null or $title == null then
                    halt
                else
                    .
                end
                | "\($title)\n\n\($extract)"
                ' <<< "$featured" \
                | fixtext \
                | fmt
        )

        if [[ -n "$onthisday" ]]; then
            printf '%s in history...\n\n%s' "$(dateconv -f '%B %dth' now)" "$onthisday" > "$dir"/onthisday.txt
        else
            rm -f "$dir"/onthisday.txt
        fi

        if [[ -n "$aotd" ]]; then
            printf 'Article of the day: %s\n' "$(fold -s -w 79 <<<"$aotd")" > "$dir"/aotd.txt
        else
            rm -f "$dir"/aotd.txt
        fi
    fi # [[ -n "$featured" ]]

    if [[ -z "$didyouknow" ]] && [[ -z "$featured" ]]; then
        exit 1
    fi
  '';

  didyouknow = pkgs.writeShellScriptBin "didyouknow" ''
    dir="''${XDG_CACHE_HOME:=$HOME/.cache}"/didyouknow

    for f in "$dir"/*.txt; do
        [[ -e "$f" ]] || {
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
      Install.WantedBy = [ "timers.target" ];
      Install.RequiredBy = [ "stw@didyouknow.service" ];
      Unit.PartOf = [ "timers.target" "stw@didyouknow.service" ];
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
        ExecStart = lib.singleton (pkgs.writeShellScript "set-didyouknow" ''
          : "''${XDG_CACHE_HOME:=$HOME/.cache}"
          : "''${XDG_RUNTIME_DIR:=/run/user/$(id -u)}"

          dir="$XDG_CACHE_HOME/didyouknow"
          runtime="$XDG_RUNTIME_DIR/didyouknow"
          [[ -d "$runtime" ] || mkdir -p "$runtime"

          for f in "$dir"/*.txt; do
              if ! [[ -e "$f" ]]; then
                  ${pkgs.systemd}/bin/systemctl --user start fetch-didyouknow.service
                  break
              fi
          done

          current_file=$(basename "$(readlink "$runtime"/stw.txt)" .txt) || current_file=

          files=( "$dir"/onthisday.txt "$dir"/didyouknow.txt "$dir"/aotd.txt )

          i=0
          while [[ "$i" -le "''${#files[@]}" ]]; do
              if [[ -e "''${files[$i]}" ]] && [[ "''${files[$i]}" == "$current_file" ]]; then
                  if [[ "$(( i + 1 ))" -gt "''${#files[@]}" ]]; then
                      # wrap around
                      next_file="''${files[0]}"
                  else
                      next_file="''${files[$(( i + 1 ))]}"
                  fi
                  break
              else
                  i=$(( i + 1 ))
              fi
          done

          if [[ -n "$next_file" ]]; then
              ln -sf "$next_file" "$runtime"/stw.txt
          else
              rm -f "$runtime"/stw.txt
          fi
        '');

        ExecStartPost = [ "-${pkgs.systemd}/bin/systemctl --user reload stw@didyouknow.service" ];
      };
    };
  };
}

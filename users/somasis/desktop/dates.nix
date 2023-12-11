{ osConfig
, config
, lib
, pkgs
, ...
}:
let
  makeDatesCalendar = pkgs.writeShellScript "make-dates-calendar" ''
    PATH=${lib.makeBinPath [
      pkgs.coreutils
      pkgs.dates
      pkgs.dateutils
      pkgs.moreutils
      pkgs.rwc
      pkgs.snooze
      pkgs.wcal
    ]}:"$PATH"

    : "''${XDG_RUNTIME_DIR:=/run/user/$(id -u)}"
    runtime="$XDG_RUNTIME_DIR/dates-calendar"

    output="$runtime/output.txt"
    calendar="$runtime/calendar.txt"
    dates="$runtime/dates.txt"
    events="$runtime/events.txt"
    width="$runtime/width.txt"
    height="$runtime/height.txt"

    mkdir -p "$runtime"

    trap 'trap - TERM EXIT; rm -f "$output"' EXIT INT TERM QUIT HUP
    touch "$output" "$calendar" "$dates" "$events" "$width" "$height"

    generate_output() {
        {
            line_length=64
            [ -s "$width" ] && [ "$(<"$width")" -ge 64 ] && line_length=$(<"$width")
            paste -d ' ' "$calendar" "$dates" | tee >(wc -L > "$width")
            cat "$events" | ifne ellipsis "$line_length"
        } | ifne sponge "$output"
        wc -l < "$output" > "$height"
    }

    if [ -e "$calendar" ] && [ "$(stat -c %Y "$calendar")" -lt "$(dateconv -f %s today)" ]; then
        printf '...\n' > "$calendar"
    fi

    {
        while [ -e "$calendar" ]; do
            wcal -i \
                | head \
                | sed -E \
                    -e 's/^([0-9]+) +([0-9A-Za-z]{3,}+)/\1\t\2\t/' \
                    -e '/^[0-9]+ +/ s/  +/\t\t/' \
                    -e 's/\t */\t/g' \
                    -e 's/\t([0-9] )/\t \1/' \
                    -e 's/$/ /' \
                    -e 's/^([0-9 ]+)\t([A-Za-z]+)\t/\2\t\t/' \
                    -e 's/^([0-9]+)\t([0-9]+)\t/\1\t\t/' \
                    -e 's/^([0-9]+)/ \1/' \
                    -e 's/\t\t/\t/' \
                    -e 's/ $//' \
                    -e 's/\t/ /' \
                    -e '/^Wk/ s/^Wk  //' \
                | sponge "$calendar"
            snooze
        done
    } &

    {
        while [ -e "$dates" ]; do
            dates -r \
                | sed -E 's/(\S+) */\1\t/g; s/^(\S+)\t/\1\t/' \
                | table -o ' ' -R7 \
                | sponge "$dates"
            snooze -H'*' -M'*' -S'*'
        done
    } &

    {
        while [ -e "$events" ]; do
            khal-personal list --format '{cancelled}{start-end-time-style} {title}' today 2d \
                | ifne cat <(echo) /dev/stdin \
                | ifne sponge "$events"
            snooze -H'*' -M'*'
        done
    } &

    generate_output
    while rwc -e "$calendar" "$dates" "$events" "$width" >/dev/null 2>/dev/null; do
        generate_output
    done
  '';

  dates-calendar = pkgs.writeShellScriptBin "dates-calendar" ''
    PATH=${lib.makeBinPath [ pkgs.coreutils ]}:"$PATH"
    : "''${XDG_RUNTIME_DIR:=/run/user/$(id -u)}"
    output="$XDG_RUNTIME_DIR/dates-calendar/output.txt"
    cat "$output"
  '';

  stw-dates-calendar = pkgs.writeShellScript "stw-dates-calendar" ''
    PATH=${lib.makeBinPath [ pkgs.coreutils pkgs.rwc ]}:"$PATH"
    : "''${XDG_RUNTIME_DIR:=/run/user/$(id -u)}"
    output="$XDG_RUNTIME_DIR/dates-calendar/output.txt"
    cat "$output" 2>/dev/null
    rwc -e "$output" >/dev/null 2>&1
  '';
in
{
  home.packages = [ dates-calendar pkgs.dates ];

  persist.directories = [ "etc/dates" ];
  xdg.configFile."dates/_".source = config.lib.file.mkOutOfStoreSymlink "/etc/localtime";

  services.stw.widgets.dates = {
    enable = false;

    command = stw-dates-calendar;

    text.font = "monospace:size=10";
    window.color = config.theme.colors.brightBlack;
    text.color = config.theme.colors.foreground;
    window.position.x = "-0";
    window.position.y = 48;
    window.padding = 12;
    update = -1;

    window.top = true;
  };

  systemd.user.services = {
    "stw-dates" = {
      Unit.BindsTo = [ "panel.service" ];
      Unit.Requires = [ "make-dates-calendar.service" ];
    };

    "make-dates-calendar" = {
      Unit.Description = "Create calendar for stw-dates widget";
      Unit.BindsTo = [ "stw-dates.service" ];
      Unit.StopWhenUnneeded = true;
      Unit.PropagatesStopTo = [ "stw-dates.service" ];
      Service = {
        Type = "simple";
        ExecStart = makeDatesCalendar;
      };
    };
  };
}

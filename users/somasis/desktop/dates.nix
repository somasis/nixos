{ osConfig
, config
, lib
, pkgs
, ...
}:
let
  makeDatesCalendar = pkgs.writeShellScript "make-dates-calendar" ''
    PATH=${lib.makeBinPath [ pkgs.coreutils pkgs.dates pkgs.moreutils pkgs.rwc pkgs.snooze pkgs.wcal ]}:"$PATH"

    : "''${XDG_RUNTIME_DIR:=/run/user/$(id -u)}"
    runtime="$XDG_RUNTIME_DIR/dates-calendar"

    output="$runtime/output.txt"
    calendar="$runtime/calendar.txt"
    dates="$runtime/dates.txt"

    mkdir -p "$runtime"

    trap 'trap - TERM EXIT; rm -f "$calendar" "$dates" "$output"' EXIT INT TERM QUIT HUP
    touch "$calendar" "$dates" "$output"

    {
        while [ -e "$calendar" ]; do
            wcal -i \
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
                    -e '10q' \
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

    while rwc -e "$calendar" "$dates" >/dev/null; do
        paste "$calendar" "$dates" \
            | tr '\t' ' ' \
            | sponge "$output"
    done
  '';

  datesCalendar = pkgs.writeShellScriptBin "dates-calendar" ''
    PATH=${lib.makeBinPath [ pkgs.coreutils ]}:"$PATH"
    : "''${XDG_RUNTIME_DIR:=/run/user/$(id -u)}"
    output="$XDG_RUNTIME_DIR/dates-calendar/output.txt"
    cat "$output"
  '';
in
{
  home.packages = [ pkgs.dates datesCalendar ];

  persist.directories = [ "etc/dates" ];
  xdg.configFile."dates/_".source = config.lib.file.mkOutOfStoreSymlink "/etc/localtime";

  services.stw.widgets.dates = {
    enable = false;

    command = "dates-calendar";

    text.font = "monospace:size=10";
    window.color = config.xresources.properties."*color8";
    text.color = config.xresources.properties."*foreground";
    window.position.x = "-0";
    window.position.y = 48;
    window.padding = 12;
    update = 1;

    window.top = true;
  };

  systemd.user.services = {
    "stw@dates" = {
      Unit.BindsTo = [ "panel.service" ];
      Unit.Requires = [ "make-dates-calendar.service" ];
    };

    "make-dates-calendar" = {
      Unit.Description = "Create calendar for stw@dates widget";
      Unit.BindsTo = [ "stw@dates.service" ];
      Unit.StopWhenUnneeded = true;
      Unit.PropagatesStopTo = [ "stw@dates.service" ];
      Service = {
        Type = "simple";
        ExecStart = "${makeDatesCalendar}";
      };
    };
  };
}

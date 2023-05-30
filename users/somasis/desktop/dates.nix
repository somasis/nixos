{ nixosConfig
, config
, lib
, pkgs
, ...
}:
let
  makeDatesCalendar = pkgs.writeShellScript "make-dates-calendar" ''
    PATH=${lib.makeBinPath [ pkgs.coreutils pkgs.dates pkgs.khal pkgs.moreutils pkgs.rwc pkgs.snooze ]}:"$PATH"

    : "''${XDG_RUNTIME_DIR:=/run/user/$(id -u)}"
    output="$XDG_RUNTIME_DIR/dates-calendar.txt"

    khal=$(mktemp)
    dates=$(mktemp)

    trap 'trap - TERM EXIT; rm -f "$khal" "$dates" "$output"' EXIT INT TERM QUIT HUP

    {
        while [ -e "$khal" ]; do
            khal calendar today -f "" --day-format "" -o \
                | head -n +8 \
                | cut -c-25 \
                | sponge "$khal"
            snooze
        done
    } &

    {
        while [ -e "$dates" ]; do
            dates -r | sponge "$dates"
            snooze -H'*' -M'*' -S'*'
        done
    } &

    touch "$khal" "$dates" "$output"
    while rwc -ep "$khal" "$dates" >/dev/null; do
        paste "$khal" "$dates" | tr '\t' ' ' | sponge "$output"
    done
  '';

  datesCalendar = pkgs.writeShellScriptBin "dates-calendar" ''
    PATH=${lib.makeBinPath [ pkgs.coreutils pkgs.snooze ]}:"$PATH"
    : "''${XDG_RUNTIME_DIR:=/run/user/$(id -u)}"
    output="$XDG_RUNTIME_DIR/dates-calendar.txt"
    cat "$output"
    [ -t 1 ] || snooze -H'*' -M'*' -S'*'
  '';
in
{
  home.packages = [ pkgs.dates datesCalendar ];

  persist.directories = [ "etc/dates" ];
  xdg.configFile."dates/_".source = "${pkgs.tzdata}/share/zoneinfo/${nixosConfig.time.timeZone}";

  somasis.chrome.stw.widgets.dates = {
    enable = false;

    command = ''
      dates-calendar
    '';

    text.font = "monospace:size=10";
    window.color = config.xresources.properties."*color8";
    text.color = config.xresources.properties."*foreground";
    window.position.x = "-0";
    window.position.y = 48;
    window.padding = 12;
    update = -1;

    window.top = true;
  };

  systemd.user.services = {
    "stw@dates" = {
      Unit.BindsTo = [ "panel.service" ];
      Unit.Requires = [ "make-dates-calendar.service" ];
    };

    "make-dates-calendar" = {
      Unit.BindsTo = [ "stw@dates.service" ];
      Service = {
        Type = "simple";
        ExecStart = "${makeDatesCalendar}";
        StopWhenUnneeded = true;
      };
    };
  };
}

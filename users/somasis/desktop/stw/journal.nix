{ pkgs, config, ... }: {
  systemd.user.services.stw-journal =
    let
      getJournal = pkgs.writeShellScript "stw-journal" ''
        width="$1"
        height="$2"
        shift 2

        # ${pkgs.systemd}/bin/journalctl -n "$height" "$@" \
        #     | tail -n "$height" \
        #     | ${pkgs.xe}/bin/xe -N0v printf "%-''${width}s\n" \
        #     | ellipsis "$width"

        # Wait for next line in the syslog
        ${pkgs.systemd}/bin/journalctl -f -n 0 -o cat --output-fields=_HOSTNAME \
            | head -n1 >/dev/null

        ${pkgs.systemd}/bin/journalctl "$@" -n "$height" -o json \
            | ${config.programs.jq.package}/bin/jq -r '"\(._SOURCE_REALTIME_TIMESTAMP // .__REALTIME_TIMESTAMP | tonumber | strflocaltime("%H:%M:%S %p"))\t\(.SYSLOG_IDENTIFIER // (._CMDLINE | sub(".*/"; "")))\(if ._PID != null then "[" + ._PID + "]" else "" end)\t\(.MESSAGE)"' \
            | ${pkgs.util-linux}/bin/column -s "$(printf '\t')" -t -c "$width" -R 2 -W 3 \
            | tail -n "$height"
      '';
    in
    {
      Unit = {
        Description = "Show a tail of the system journal on the desktop";
        StartLimitInterval = 0;
      };
      Install.WantedBy = [ "stw.target" ];
      Unit.PartOf = [ "stw.target" ];

      Service.Type = "simple";
      Service.ExecStart = ''
        stw \
            -F 'monospace:style=heavy:size=8' \
            -f '${config.xresources.properties."*color3"}' \
            -A 0 \
            -x 0 -y -0 \
            -B 24 \
            -p -1 \
            ${getJournal} 275 10
      '';
    };
}

{ lib
, writeShellApplication
, writeShellScript

, coreutils
, lemonbar
, procps
, systemd

, mmutils

, toEnvVarName

, debug ? false
, colors ? { }
, fonts ? { }
, lemonbarExtraArgs ? ""
, lemonbarPackage ? lemonbar
, modules ? [ ]
, interpreter ? "/bin/sh -x"
}:
let
  inherit (builtins)
    attrNames
    attrValues
    catAttrs
    typeOf
    ;

  inherit (lib)
    boolToString
    concatLines
    concatStrings
    concatStringsSep
    escapeShellArg
    filter
    gtExe
    imap0
    makeBinPath
    mapAttrsToList
    toShellVar
    toUpper
    ;

  inherit (lib.cli) toGNUCommandLineShell;

  moduleToCommand = module:
    let
      monitor =
        if module.monitor == "primary" then
          ''"$PANEL_MONITOR_PRIMARY"''
        else
          escapeShellArg module.monitor
      ;

      command =
        writeShellScript "panel-module-${module.name}" ''
          : "''${PANEL_MONITOR:?PANEL_MODULE_NAME: \$PANEL_MONITOR is unset}"
          export ${toShellVar "PANEL_MODULE_NAME" module.name}

          case "$PANEL_MONITOR" in
              ${monitor}) : ;;
              *)
                  if [[ -n "$PANEL_DEBUG" ]]; then
                      printf \
                          'debug: not starting module "%s" on monitor "%s"; requires monitor "%s"\n' \
                          "$PANEL_MODULE_NAME" \
                          "$PANEL_MONITOR" \
                          ${escapeShellArg module.monitor} \
                          >&2
                  fi

                  return
                  ;;
          esac

          ${writeShellScript "panel-module-command-${module.name}" module.command} \
              | while IFS= read -r output; do
                  printf '%s\t%s\n' "$PANEL_MODULE_NAME" "$output"
              done
        '';
    in
    "${command} &"
  ;

  modulesToCommands = modules:
    if modules != [ ] then
      ''{ ${concatStringsSep "; " (map moduleToCommand modules)} }''
    else
      ":"
  ;

  modulesToCaseStatements = modules:
    concatLines (
      map
        (module: ''${escapeShellArg module.name}) PANEL_MODULE_${toEnvVarName module.name}="$module_output" ;;'')
        modules
    )
  ;

  modulesToVariables = modules:
    concatStrings
      (
        map
          (module:
            let variable = toEnvVarName "${module.name}";
            in "\${PANEL_MODULE_${variable}}"
          )
          modules
      )
  ;

  moduleRuntimeInputs = modules: catAttrs "runtimeInputs" (attrValues modules);
in
(writeShellApplication {
  name = "panel";

  runtimeInputs = [
    lemonbarPackage
    coreutils
    procps

    # Used for readiness notification.
    systemd

    # Used for getting monitor information (list of monitors, primary monitor).
    mmutils
  ];

  text = ''
    : "''${DISPLAY:?error: \$DISPLAY is unset}"

    : "''${TMPDIR:=/tmp}"
    : "''${XDG_RUNTIME_DIR:=$TMPDIR}"

    : "''${PANEL_RUNTIME:=$XDG_RUNTIME_DIR/panel.$DISPLAY}"
    : "''${PANEL_DEBUG:=${boolToString debug}}"

    export PANEL_RUNTIME PANEL_DEBUG
    ${concatLines (mapAttrsToList (name: v: "export " + toShellVar "PANEL_COLOR_${toEnvVarName name}" v) colors)}
    ${concatLines (imap0 (i: name: "export " + toShellVar "PANEL_FONT_${toEnvVarName name}" i) (attrNames fonts))}

    cleanup() {
        if [[ -v NOTIFY_SOCKET ]]; then systemd-notify --stopping; fi

        trap - TERM
        rm -rf "$PANEL_RUNTIME"
        kill 0
    }

    formatter_first_run=true
    formatter() {
        : "''${PANEL_MONITOR:?formatter(): \$PANEL_MONITOR is unset}"

        local IFS
        IFS=$'\t'

        local module_name module_output
        local modules_aligned_left modules_aligned_center modules_aligned_right

        while read -r module_name module_output; do
            case "$module_name" in
                ${modulesToCaseStatements modules}
                *)
                    if [[ -n "$PANEL_DEBUG" ]]; then
                        printf 'error: unknown input to panel: %s:%s\n' "$module_name" "$module_output" >&2
                    fi

                    return 127
                    ;;
            esac

            modules_aligned_left="${modulesToVariables (filter (module: module.align == "left") modules)}"
            modules_aligned_center="${modulesToVariables (filter (module: module.align == "center") modules)}"
            modules_aligned_right="${modulesToVariables (filter (module: module.align == "right") modules)}"

            printf '%%{S%s}%%{l}%s%%{c}%s%%{r}%s\n' \
                "$PANEL_MONITOR" \
                "$modules_aligned_left" \
                "$modules_aligned_center" \
                "$modules_aligned_right"

            if [[ "$formatter_first_run" == true ]]; then
                formatter_first_run=false
                if [[ -v NOTIFY_SOCKET ]]; then systemd-notify --ready; fi
            fi
        done
    }

    mapfile -t monitors < <(lsm)
    primary_monitor=$(lsm -p)

    # Initialize all monitor FIFOs.
    mkdir -p "$PANEL_RUNTIME"/monitors
    for PANEL_MONITOR in "''${monitors[@]}"; do
        mkfifo "$PANEL_RUNTIME"/monitors/"$PANEL_MONITOR".fifo
    done

    # Redirect monitors.fifo -> monitors/*.fifo.
    mkfifo "$PANEL_RUNTIME"/monitors.fifo
    < "$PANEL_RUNTIME"/monitors.fifo tee "$PANEL_RUNTIME"/monitors/*.fifo &

    if [[ -n "$PANEL_DEBUG" ]]; then printf 'starting modules for all monitors...\n' >&2; fi

    export PANEL_MONITOR=all
    ${modulesToCommands (filter (module: module.monitor == "all") modules)} >"$PANEL_RUNTIME"/monitors.fifo &

    for PANEL_MONITOR in "''${monitors[@]}"; do
        if [[ "$PANEL_MONITOR" == "$primary_monitor" ]]; then
            if [[ -n "$PANEL_DEBUG" ]]; then printf 'starting modules for monitor "%s" (primary)...\n' "$PANEL_MONITOR" >&2; fi

            export PANEL_MONITOR=primary
            ${modulesToCommands (filter (module: module.monitor == "primary") modules)} >"$PANEL_RUNTIME"/monitors/"$PANEL_MONITOR".fifo &
        else
            if [[ -n "$PANEL_DEBUG" ]]; then printf 'starting modules for monitor "%s"...\n' "$PANEL_MONITOR" >&2; fi

            export PANEL_MONITOR
            ${modulesToCommands (filter (module: module.monitor != "all" && module.monitor != "primary") modules)} >"$PANEL_RUNTIME"/monitors/"$PANEL_MONITOR".fifo &
        fi
    done
    unset PANEL_MONITOR

    trap \
        "cleanup" \
        EXIT \
        INT \
        QUIT \
        TERM

    PANEL_MONITOR_NUMBER=0
    for PANEL_MONITOR in "''${monitors[@]}"; do
        PANEL_MONITOR_NUMBER=$((PANEL_MONITOR_NUMBER + 1))

        case "$PANEL_MONITOR_NUMBER" in
            1) PANEL_COLOR_MONITOR="$PANEL_COLOR_RED"    ;;
            2) PANEL_COLOR_MONITOR="$PANEL_COLOR_GREEN"  ;;
            3) PANEL_COLOR_MONITOR="$PANEL_COLOR_YELLOW" ;;
            4) PANEL_COLOR_MONITOR="$PANEL_COLOR_GREEN"  ;;
            5) PANEL_COLOR_MONITOR="$PANEL_COLOR_YELLOW" ;;
            6) PANEL_COLOR_MONITOR="$PANEL_COLOR_BLACK"  ;;
            *) PANEL_COLOR_MONITOR="$PANEL_COLOR_ACCENT" ;;
        esac

        export \
            PANEL_MONITOR \
            PANEL_MONITOR_NUMBER \
            PANEL_COLOR_MONITOR

        formatter <"$PANEL_RUNTIME"/monitors/"$PANEL_MONITOR".fifo \
            | lemonbar \
                -n "panel" \
                ${lemonbarExtraArgs} \
            | PATH=${lib.makeBinPath (moduleRuntimeInputs modules)} ${interpreter} &
    done
    wait
  '';
}) // ({
  meta = {
    description = "A lemonbar-based panel.";
    license = lib.licenses.unlicense;
  };
})

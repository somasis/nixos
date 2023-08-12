{ lib
, symlinkJoin
, writeShellApplication

, coreutils
, dateutils
, gnugrep
, gnused
, htmlq
, jq
, libarchive

, borgConfig ? { }
}:
let
  extraArgs =
    if borgConfig.extraArgs ? false then
      borgConfig.extraArgs
    else
      ""
  ;

  preHook =
    if borgConfig.preHook ? false then
      borgConfig.preHook
    else
      ""
  ;

  make = name: runtimeInputs:
    writeShellApplication {
      inherit name;
      inherit runtimeInputs;

      text =
        ''
          # shellcheck disable=SC2034,SC2090
          ${preHook}

          type=$(type -t borg)
          case "$type" in
              function)
                  prev_borg=$(declare -f borg)

                  eval "prev_$prev_borg"
                  borg() {
                      local ${lib.toShellVar "extraArgs" extraArgs}

                      # shellcheck disable=SC2086
                      prev_borg $extraArgs "$@"
                  }
                  ;;
              *)
                  borg() {
                      local ${lib.toShellVar "extraArgs" extraArgs}

                      # shellcheck disable=SC2086
                      command borg $extraArgs "$@"
                  }
                  ;;
          esac
        ''
        + builtins.readFile (./. + "/${name}.bash")
      ;
    }
  ;
in
symlinkJoin {
  name = "borg-takeout";

  paths = [
    (make "borg-import-google" [ coreutils gnugrep htmlq libarchive ])
    (make "borg-import-instagram" [ coreutils dateutils jq libarchive ])
    (make "borg-import-letterboxd" [ coreutils jq libarchive ])
    (make "borg-import-tumblr" [ coreutils jq libarchive ])
    (make "borg-import-twitter" [ coreutils gnused jq libarchive ])
  ];

  meta = with lib; {
    description = "Various utilities for using `borg` to process archives from online services";
    license = licenses.unlicense;
    maintainers = with maintainers; [ somasis ];
  };
}

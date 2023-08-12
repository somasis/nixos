final: prev:
let
  inherit (prev)
    lib

    jq
    python3Packages

    callPackage
    runtimeShell
    writeScript
    writeTextFile
    ;
in
rec
{
  wrapCommand = callPackage ./wrapCommand;

  writeJqScript = name: args: text:
    let
      args' = lib.cli.toGNUCommandLineShell { } (args // {
        from-file = writeScript name ''
          #!${jq}/bin/jq -f
          ${text}
        '';
      });
    in
    writeTextFile {
      inherit name;
      executable = true;

      checkPhase = ''
        e=0
        ${jq}/bin/jq -n ${args'} || e=$?

        # 3: syntax error
        [ "$e" -eq 3 ] && exit 1 || :

        exit 0
      '';

      text = ''
        #!${runtimeShell}
        exec ${jq}/bin/jq ${args'} "$@"
      '';
    }
  ;

  screenshot = callPackage ./screenshot { };
  xinput-notify = callPackage ./xinput-notify { };

  dates = callPackage ./dates { };
  json2nix = callPackage ./json2nix { };
  mimetest = callPackage ./mimetest { };
  nocolor = callPackage ./nocolor { };
  playtime = callPackage ./playtime { };
  table = callPackage ./table { };

  dmenu = callPackage ./dmenu { };
  dmenu-emoji = callPackage ./dmenu-emoji { };
  dmenu-pass = callPackage ./dmenu-pass { };
  dmenu-run = callPackage ./dmenu-run { };
  dmenu-session = callPackage ./dmenu-session { };

  pass-meta = callPackage ./pass-meta { };
  qute-pass = callPackage ./qute-pass { };

  borg-takeout = callPackage ./borg-takeout { };
  qutebrowser-sync = callPackage ./qutebrowser-sync { };

  ffsclient = callPackage ./ffsclient { };
  mail-deduplicate = python3Packages.callPackage ./mail-deduplicate { };
  notify-send-all = callPackage ./notify-send-all { };
  wcal = callPackage ./wcal { };
}

{ lib
, pkgs
}:
let
  inherit (pkgs)
    runtimeShell

    writeScript
    writeTextFile
    ;
in
{
  writeJqScript = name: args: text:
    let
      args' = lib.cli.toGNUCommandLineShell { } (args // {
        from-file = writeScript name ''
          #!${pkgs.jq}/bin/jq -f
          ${text}
        '';
      });
    in
    writeTextFile {
      inherit name;
      executable = true;

      checkPhase = ''
        e=0
        ${pkgs.jq}/bin/jq -n ${args'} || e=$?

        # 3: syntax error
        [ "$e" -eq 3 ] && exit 1 || :

        exit 0
      '';

      text = ''
        #!${runtimeShell}
        exec ${pkgs.jq}/bin/jq ${args'} "$@"
      '';
    };
}

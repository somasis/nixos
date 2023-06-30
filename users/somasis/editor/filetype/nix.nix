{ lib
, pkgs
, config
, ...
}:
let
  format = pkgs.writeShellScript "format" ''
    set -x
    t_orig=$(mktemp)
    t_out=$(mktemp)

    tee "$t_orig" > "$t_out"

    e=0
    if \
        ${config.nix.package}/bin/nix fmt "$t_out" >/dev/null 2>&1 \
        || ${pkgs.nixpkgs-fmt}/bin/nixpkgs-fmt "$t_out" >/dev/null 2>&1
        then
        cat "$t_out"
    else
        cat "$t_orig"
        e=1
    fi
    rm -f "$t_orig" "$t_out"
    exit "$e"
  '';

  lint = pkgs.writeShellScript "lint" ''
    ${pkgs.statix}/bin/statix check -o json "$@" 2>/dev/null \
        | ${config.programs.jq.package}/bin/jq -r '
            .file as $file
                | .report
                | map(
                    (.severity | ascii_downcase) as $severity
                        | (.note | ascii_downcase) as $note
                        | .diagnostics
                        | map("\($file):\(.at.from.line):\(.at.to.line):\(try $severity + ": ")\(.message)\(try " (" + $note + ")")")
                )
                | flatten[]
        '
  '';
in
{
  programs.kakoune.config.hooks = [{
    name = "WinSetOption";
    option = "filetype=nix";
    commands =
      ''
        set-option window tabstop 2
        set-option window indentwidth 2

        set-option window formatcmd "${format}"
        set-option window lintcmd "${lint}"
      '';
  }];
}

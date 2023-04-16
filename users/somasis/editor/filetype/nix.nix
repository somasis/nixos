{ pkgs, config, ... }:
let
  # format = pkgs.writeShellScript "format" ''
  #   d=''${1%/*}

  #   t=$(mktemp "$d"/.tmp.XXXXXXXXXX)

  #   cat "$1" > "$t"

  #   if ${pkgs.nixFlakes}/bin/nix fmt "$t" 2>/dev/null; then
  #       cat "$t"
  #   else
  #       ${pkgs.nixpkgs-fmt}/bin/nixpkgs-fmt "$t" || cat "$1"
  #   fi

  #   rm -f "$t"
  # '';
  format = pkgs.writeShellScript "format" ''
    ${config.nix.package}/bin/nix fmt -- "$@" || ${pkgs.nixpkgs-fmt}/bin/nixpkgs-fmt -- "$@"
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

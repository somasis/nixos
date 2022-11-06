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
  format = "${pkgs.nixpkgs-fmt}/bin/nixpkgs-fmt";
  lint = pkgs.writeShellScript "lint" ''
    ${pkgs.nix-linter}/bin/nix-linter -j "$1" \
        | ${config.programs.jq.package}/bin/jq -r '
            . | (
                .file + ":" +
                (.pos.spanBegin | (.sourceLine | tostring) + ":" + (.sourceColumn | tostring)) +
                ": warning: " + .description
            )
        '
  '';
in
{
  programs.kakoune.config.hooks = [
    {
      name = "WinSetOption";
      option = "filetype=nix";
      commands =
        ''
          set-option window tabstop 2
          set-option window indentwidth 2

          set-option window formatcmd "${format}"
          set-option window lintcmd "${lint}"
        '';
    }
  ];
}

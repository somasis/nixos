{ pkgs, config, ... }:
let
  format = ''
    ${pkgs.nodePackages.prettier}/bin/prettier
        --tab-width=%opt{indentwidth}
        --print-width=%opt{autowrap_column}
        --config-precedence prefer-file
        --stdin-filepath=%val{buffile}
  '';

  # CSS
  lintCSS = pkgs.writeShellScript "lint" ''
    ${pkgs.nodePackages.stylelint}/bin/stylelint --formatter unix --stdin-filename="$kak_buffile" < "$1"
  '';

  # JavaScript
  lintJavaScript = pkgs.writeShellScript "lint" ''
    ${pkgs.nodePackages.eslint}/bin/eslint -f unix --stdin --stdin-filename "$kak_buffile" < "$1"
  '';

  # JSON
  formatJSON = "${config.programs.jq.package}/bin/jq --indent %opt{tabstop} -S .";
  lintJSON = pkgs.writeShellScript "lint" ''
    ${config.programs.jq.package}/bin/jq < "$1" \
        | awk -v filename="$1" '
            / at line [0-9]+, column [0-9]+$/ {
                line=$(NF - 2);
                column=$NF;
                sub(/ at line [0-9]+, column [0-9]+$/, "");
                printf "%s:%d:%d: error: %s", filename, line, column, $0;
            }
        '
  '';
in
{
  programs.kakoune.config.hooks = [
    {
      name = "WinSetOption";
      option = "filetype=(javascript|yaml)";
      commands = "set-option window formatcmd '${format}'";
    }

    # CSS
    {
      name = "WinSetOption";
      option = "filetype=css";
      commands = "set-option window lintcmd '${lintCSS}'";
    }

    # JavaScript
    {
      name = "WinSetOption";
      option = "filetype=javascript";
      commands = "set-option window lintcmd '${lintJavaScript}'";
    }

    # JSON
    {
      name = "WinSetOption";
      option = "filetype=json";
      commands = ''
        set-option window tabstop 2
        set-option window formatcmd '${formatJSON}'
        set-option window lintcmd '${lintJSON}'
      '';
    }
  ];
}

{ pkgs, ... }:
let
  lint = pkgs.writeShellScript "lint" ''
    ${pkgs.yamllint}/bin/yamllint -f parsable "$1" \
        | sed "s/ \[\(.*\)\] / \1: /"
  '';
in
{
  programs.kakoune.config.hooks = [
    {
      name = "WinSetOption";
      option = "filetype=yaml";
      commands = ''set-option window lintcmd "${lint}"'';
    }
  ];
}

{ pkgs, ... }:
let
  lint = pkgs.writeShellScript "lint" ''
    ${pkgs.yamllint}/bin/yamllint -f parsable -s "$1" \
        | sed -E "s/ \[\(.*\)\] / \1: /"
  '';
in
{
  programs.kakoune.config.hooks = [{
    name = "WinSetOption";
    option = "filetype=yaml";
    commands = ''
      set-option window lintcmd "${lint}"
    '';
  }];
}

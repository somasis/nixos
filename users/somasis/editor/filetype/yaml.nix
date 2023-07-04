{ pkgs
, lib
, ...
}:
let
  lint = pkgs.writeShellScript "lint-yaml" ''
    PATH=${lib.makeBinPath [ pkgs.gnused pkgs.yamllint ]}

    yamllint -f parsable -s "$1" \
        | sed -E "s/ \[\(.*\)\] / \1: /"
  '';
in
{
  home.packages = [ pkgs.yamllint ];

  programs.kakoune.config.hooks = [{
    name = "WinSetOption";
    option = "filetype=yaml";
    commands = ''
      set-option window lintcmd "${lint}"
    '';
  }];
}

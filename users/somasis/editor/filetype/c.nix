{ pkgs
, lib
, ...
}:
let
  format = "${pkgs.clang-tools}/bin/clang-format -style=file";
  lint = pkgs.writeShellScript "lint-clang" ''
    PATH=${lib.makeBinPath [ pkgs.clang-tools ]}
    clang-tidy --quiet "$@" 2>/dev/null
  '';
in
{
  home.packages = [ pkgs.clang-tools ];

  programs.kakoune.config.hooks = [{
    name = "WinSetOption";
    option = "filetype=(c|cc|cpp|h)";
    commands = ''
      clang-enable-autocomplete
      clang-enable-diagnostics

      set-option window formatcmd ${format}
      set-option window lintcmd ${lint}
    '';
  }];
}

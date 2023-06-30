# C and C++.
{ pkgs, ... }:
let
  format = "${pkgs.clang-tools}/bin/clang-format -style=file";
  lint = pkgs.writeShellScript "lint" ''
    ${pkgs.clang-tools}/bin/clang-tidy --quiet "$@" 2>/dev/null
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

      set-option window formatcmd "${format}"
      set-option window lintcmd "${lint}"
    '';
  }];
}

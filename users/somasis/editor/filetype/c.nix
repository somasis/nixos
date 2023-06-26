{ pkgs, ... }:
let
  format = "${pkgs.clang-tools}/bin/clang-format -style=file";
  lint = pkgs.writeShellScript "lint" ''
    ${pkgs.clang-tools}/bin/clang-tidy --quiet "$@" 2>/dev/null
  '';
in
{
  programs.kakoune.config.hooks = [
    # C and C++.
    {
      name = "WinSetOption";
      option = "filetype=(c|cc|cpp|h)";
      commands = ''
        clang-enable-autocomplete
        clang-enable-diagnostics

        set-option window formatcmd "${format}"
        set-option window lintcmd "${lint}"
      '';
    }
  ];
}

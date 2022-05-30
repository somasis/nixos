{ pkgs, ... }:
let
  # `black-macchiato` is used over `black`, as it handles
  # Python fragments better than regular `black` does
  format = "${pkgs.black-macchiato}/bin/black-macchiato -";

  lint = pkgs.writeShellScript "lint" ''
    ${pkgs.python3Packages.pylint}/bin/pylint \
        --msg-template='{path}:{line}:{column}: {category}: {msg_id}: {msg} ({symbol})' "$@" \
        | awk -F: 'BEGIN { OFS=":" } { if (NF == 6) { $3 += 1; print } }'
  '';
in
{
  programs.kakoune.config.hooks = [
    {
      name = "WinSetOption";
      option = "filetype=python";
      commands = ''
        set-option window formatcmd "${format}"
        set-option window lintcmd "${lint}"
      '';
    }
  ];
}

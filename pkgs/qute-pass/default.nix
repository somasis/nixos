{ lib
, writeShellApplication

, coreutils
  # , dmenu
  # , dmenu-pass
, gnused
  # , pass
, util-linux
, xdotool
}:
(writeShellApplication {
  name = "qute-pass";

  runtimeInputs = [
    coreutils
    # dmenu
    # dmenu-pass
    gnused
    # pass
    util-linux
    xdotool
  ];

  text = builtins.readFile ./qute-pass.sh;
}) // {
  meta = with lib; {
    description = "Glue qutebrowser to pass and dmenu-pass";
    license = licenses.unlicense;
    maintainers = with maintainers; [ somasis ];
  };
}

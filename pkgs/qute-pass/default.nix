{ lib
, writeShellApplication

, coreutils
, dmenu-pass
, gnused
, pass
, trurl
, util-linux
, xdotool
}:
(writeShellApplication {
  name = "qute-pass";

  runtimeInputs = [
    coreutils
    dmenu-pass
    gnused
    pass
    trurl
    util-linux
    xdotool
  ];

  text = builtins.readFile ./qute-pass.bash;
}) // {
  meta = with lib; {
    description = "Glue qutebrowser to pass and dmenu-pass";
    license = licenses.unlicense;
    maintainers = with maintainers; [ somasis ];
  };
}

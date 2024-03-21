{ lib
, writeShellApplication

, xorg

, dmenu
, bspwm
, gnugrep
, systemd
}:
let inherit (xorg) xset; in
writeShellApplication {
  name = "dmenu-session";

  runtimeInputs = [
    dmenu
    bspwm
    gnugrep
    systemd
    xset
  ];

  text = builtins.readFile ./dmenu-session.sh;

  meta = with lib; {
    description = "A logout/etc. prompt that uses dmenu";
    license = licenses.unlicense;
    maintainers = with maintainers; [ somasis ];
  };
}

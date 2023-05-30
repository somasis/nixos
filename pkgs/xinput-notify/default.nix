{ lib
, writeShellApplication

, xorg

, coreutils
, gnugrep
, gnused
, libnotify
, xe
}:
let
  inherit (xorg) xinput;
in
(writeShellApplication {
  name = "xinput-notify";

  runtimeInputs = [
    coreutils
    gnugrep
    gnused
    libnotify
    xe
    xorg.xinput
  ];

  text = builtins.readFile ./xinput-notify.sh;
}) // {
  meta = with lib; {
    description = "Toggle the state of an Xorg input device and show a notification";
    license = licenses.unlicense;
    maintainers = with maintainers; [ somasis ];
  };
}

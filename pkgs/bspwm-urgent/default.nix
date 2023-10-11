{ lib
, writeShellApplication

, coreutils
, bspwm
, libnotify
, systemd
, xdotool
}:
lib.recursiveUpdate
  (writeShellApplication {
    name = "bspwm-urgent";

    runtimeInputs = [
      bspwm
      coreutils
      libnotify
      systemd
      xdotool
    ];

    text = builtins.readFile ./bspwm-urgent.sh;
  })
  ({
    meta = with lib; {
      description = "Show a notification for bspwm(1) nodes that are marked urgent";
      license = licenses.unlicense;
      maintainers = with maintainers; [ somasis ];
    };
  })

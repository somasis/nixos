{ lib
, writeShellApplication

, bspwm
, wmutils-core
, mmutils
}:
lib.recursiveUpdate
  (writeShellApplication {
    name = "bspwm-center-window";

    runtimeInputs = [
      bspwm
      wmutils-core
      mmutils
    ];

    text = builtins.readFile ./bspwm-center-window.sh;
  })
  ({
    meta = with lib; {
      description = "Center a floating bspwm(1) node";
      license = licenses.unlicense;
      maintainers = with maintainers; [ somasis ];
    };
  })


{ lib
, writeShellApplication

, bspwm
, coreutils
, libnotify
, maim
, moreutils
, slop
, tesseract
, yq-go
, xclip
, xdg-user-dirs
, xdg-utils
, xdotool
, zbar
}:
(writeShellApplication {
  name = "screenshot";

  runtimeInputs = [
    bspwm
    coreutils
    libnotify
    maim
    moreutils
    slop
    tesseract
    yq-go
    xclip
    xdg-user-dirs
    xdg-utils
    xdotool
    zbar
  ];

  text = builtins.readFile ./screenshot.sh;
}) // {
  meta = with lib; {
    description = "Take a screenshot of the desktop";
    license = licenses.unlicense;
    maintainers = with maintainers; [ somasis ];
  };
}

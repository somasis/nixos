{ lib
, writeShellApplication

, pass-nodmenu

, coreutils
, dmenu
, findutils
, gnugrep
, gnused
, libnotify
, moreutils
, pass ? pass-nodmenu
, uq
, xclip
}:
(writeShellApplication {
  name = "dmenu-pass";

  runtimeInputs = [
    coreutils
    dmenu
    findutils
    gnugrep
    gnused
    libnotify
    moreutils
    pass
    uq
    xclip
  ];

  text = builtins.readFile ./dmenu-pass.bash;
}) // {
  meta = with lib; {
    description = "Access the password store with dmenu";
    license = licenses.unlicense;
    maintainers = with maintainers; [ somasis ];
  };
}

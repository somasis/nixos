{ lib
, writeShellApplication

, bfs
, coreutils
, dmenu
, findutils
, gnugrep
, gnused
, libnotify
, moreutils
, systemd
, uq
}:
(writeShellApplication {
  name = "dmenu-run";

  runtimeInputs = [
    bfs
    coreutils
    dmenu
    findutils
    gnugrep
    gnused
    libnotify
    moreutils
    systemd
    uq
  ];

  text = builtins.readFile ./dmenu-run.bash;
}) // {
  meta = with lib; {
    description = "An application runner that uses dmenu";
    license = licenses.unlicense;
    maintainers = with maintainers; [ somasis ];
  };
}

{ lib
, writeShellApplication

, coreutils
, dateutils
, gnugrep
, khal
}:
writeShellApplication {
  name = "playtime";

  runtimeInputs = [
    coreutils
    dateutils
    gnugrep
    khal
  ];

  text = builtins.readFile ./playtime.sh;

  meta = with lib; {
    description = "Exit unsuccessfully if you should be working right now";
    license = licenses.unlicense;
    maintainers = with maintainers; [ somasis ];
  };
}

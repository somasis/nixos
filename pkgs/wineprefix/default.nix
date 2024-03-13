{ lib
, writeShellApplication

, coreutils
, wine
}:
writeShellApplication {
  name = "wineprefix";

  runtimeInputs = [ coreutils wine ];

  text = builtins.readFile ./wineprefix.bash;

  meta = with lib; {
    mainProgram = "wineprefix";
    description = "A simple Wine prefix manager";
    license = licenses.unlicense;
    maintainers = with maintainers; [ somasis ];
  };
}

{ lib
, symlinkJoin
, writeShellApplication

, coreutils
, dateutils
, libarchive
, htmlq
, gnugrep
}:
let
  make = name: runtimeInputs:
    writeShellApplication {
      inherit name;
      inherit runtimeInputs;
      text = builtins.readFile (./. + "/${name}.bash");
    }
  ;
in
symlinkJoin {
  name = "borg-takeout";

  paths = [
    (make "borg-import-google" [ coreutils gnugrep htmlq libarchive ])
    (make "borg-import-instagram" [ coreutils dateutils jq libarchive ])
    (make "borg-import-letterboxd" [ coreutils jq libarchive ])
    (make "borg-import-tumblr" [ coreutils jq libarchive ])
    (make "borg-import-twitter" [ coreutils gnused jq libarchive ])
  ];

  meta = with lib; {
    description = "Various utilities for using `borg` to process archives from online services";
    license = licenses.unlicense;
    maintainers = with maintainers; [ somasis ];
  };
}

{ lib
, stdenvNoCC
, fetchurl
, ibus
, ibus-engines
}:
stdenvNoCC.mkDerivation {
  pname = "ibus-table-sitelen-pona";
  version = "0.1";

  src = fetchurl {
    name = "tokipona.txt";
    url = "https://raw.githubusercontent.com/Id405/sitelen-pona-ucsur-guide/main/tokipona.txt";
    sha256 = "sha256-VSyj3PzsP/+WHfkygLm7i70uPQ6yWqoj4mkf5rW4brE=";
  };

  dontUnpack = true;

  buildInputs = [ ibus ibus-engines.table ];

  buildPhase = ''
    export HOME=$TMPDIR
    ibus-table-createdb -n tokipona.db -s $src
  '';

  installPhase = ''
    mkdir -p $out/share/ibus-table/tables
    install -m 0644 tokipona.db $out/share/ibus-table/tables/tokipona.db
  '';

  meta = with lib; {
    description = "Toki Pona input method";
    license = licenses.publicDomain;
    maintainers = with maintainers; [ somasis ];
    platforms = platforms.all;
  };
}

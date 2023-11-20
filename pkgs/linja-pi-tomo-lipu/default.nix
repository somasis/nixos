{ lib
, stdenvNoCC
, fetchurl
}:
stdenvNoCC.mkDerivation rec {
  pname = "linja-pi-tomo-lipu";
  version = "0.7";

  src = fetchurl {
    url =
      "https://github.com/pguimier/linjapitomolipu/releases/download/v${version}/linjapitomolipu.${version}.ttf";
    hash = "sha256-Enr2HLTj4ayC1WyeRaHvY7ZLo+q0CEiM7/lzc/d4Oxs=";
  };

  dontUnpack = true;

  installPhase = ''
    install -D $src $out/share/fonts/truetype/${pname}.ttf
  '';

  meta = with lib; {
    description = "a monotype sitelen pona font adapted from tomo-lipu.net";
    homepage = "https://github.com/pguimier/linjapitomolipu";
    license = licenses.mit;
    platforms = platforms.all;
    maintainers = with maintainers; [ somasis ];
  };
}

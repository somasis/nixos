{ lib
, stdenvNoCC
, fetchurl
}:
let
  rev = "0f22e5a4beb5f0c577fdcc4e0f1995c64cefd547";
in
stdenvNoCC.mkDerivation rec {
  pname = "linja-luka";
  version = "1.0";

  src = fetchurl {
    url = "https://github.com/janMelon/linja-luka/raw/${rev}/font-files/linja-luka-${version}.otf";
    hash = "sha256-J5uqvmknAWE8pzuAWC6nvZILn3j/0g+2QjWdJ8ZFi+4=";
  };

  dontUnpack = true;

  installPhase = ''
    install -D $src $out/share/fonts/opentype/${pname}.otf
  '';

  meta = with lib; {
    description = "a handwriting-esque sitelen pona font, by jan Pensamin and jan Melon";
    homepage = "https://github.com/janMelon/linja-luka";
    license = licenses.ofl;
    platforms = platforms.all;
    maintainers = with maintainers; [ somasis ];
  };
}

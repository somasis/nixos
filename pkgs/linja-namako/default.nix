{ lib
, stdenvNoCC
, fetchurl
}:

let
  rev = "8436d31ba84bb9c7198f7df2ec07d5b8b56ffdf7";
in
stdenvNoCC.mkDerivation rec {
  pname = "linja-namako";
  version = "1.0.0";

  src = fetchurl {
    url = "https://web.archive.org/web/20231108052150/https://jan-sikusi.neocities.org/fonts/linjanamako.ttf";
    hash = "sha256-Ex7+v2fF95ucRAvDMj8j1SXMtbJKnfvvZvi8Q5JO1ow=";
  };

  dontUnpack = true;

  installPhase = ''
    install -D $src $out/share/fonts/truetype/${pname}.ttf
  '';

  meta = with lib; {
    description = "A serif font for Toki Pona writing system, sitelen pona";
    homepage = "https://jan-sikusi.neocities.org/html/linjanamako";

    # > It is created based on (and occasionally directly using) the letterforms
    # > of the font 'Linux Libertine'. It is a free and open-source font
    # > distributed under the GPL (General Public License) with font-exception
    # > and OFL (Open Font License).
    license = with licenses; [ ofl ];

    platforms = platforms.all;
    maintainers = with maintainers; [ somasis ];
  };
}


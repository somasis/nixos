{ lib
, stdenvNoCC
, fetchurl
}:

let
  rev = "187fedaffbc5b2746ed77cf565f9af159bf7fe93";
in
stdenvNoCC.mkDerivation rec {
  pname = "linja-suwi";
  version = "1.301";

  src = fetchurl {
    url = "https://github.com/anna328p/linjasuwi/raw/${rev}/linjasuwi.otf";
    hash = "sha256-TRQsRJssXjZsSJtRndi+YgvaiDxz4XRlBsECu8tKEWk=";
  };

  dontUnpack = true;

  installPhase = ''
    install -D $src $out/share/fonts/opentype/${pname}.otf
  '';

  meta = with lib; {
    description = "a new sitelen pona font with a sweet look";
    homepage = "https://linjasuwi.ap5.dev";
    downloadPage = "https://github.com/anna328p/linjasuwi";
    license = licenses.ofl;
    platforms = platforms.all;
    maintainers = with maintainers; [ somasis ];
  };
}

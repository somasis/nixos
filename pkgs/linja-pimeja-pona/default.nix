{ lib
, stdenvNoCC
, fetchurl
}:
let
  rev = "c9e403246491f600633daebb85734aa3cb9e3f36";
in
stdenvNoCC.mkDerivation rec {
  pname = "linja-pimeja-pona";
  version = "0.9";

  src = fetchurl {
    url = "https://github.com/RetSamys/linja-pimeja-pona/raw/${rev}/linjapimejapona${version}.otf";
    hash = "sha256-vi/A88pJJsGDwnGbeSSlX8IeoGuTxDxMIL2xVq6o8jU=";
  };

  dontUnpack = true;

  installPhase = ''
    install -D $src $out/share/fonts/opentype/${pname}.otf
  '';

  meta = with lib; {
    description =
      "a heavy sitelen pona font originally based on linja pimeja, by jan Ke Tami";
    homepage =
      "https://www.reddit.com/r/tokipona/comments/qn96f7/linja_pimeja_pona/";
    downloadPage = "http://antetokipona.infinityfreeapp.com/font/";
    license = licenses.ofl;
    platforms = platforms.all;
    maintainers = with maintainers; [ somasis ];
  };
}

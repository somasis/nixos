{ lib, fetchurl }:

let
  pname = "linja-pimeja-pona";
  version = "0.9";
  rev = "c9e403246491f600633daebb85734aa3cb9e3f36";
in
fetchurl {
  name = "${pname}-${version}";
  url =
    "https://github.com/RetSamys/linja-pimeja-pona/raw/${rev}/linjapimejapona${version}.otf";

  downloadToTemp = true;
  recursiveHash = true;
  postFetch = ''
    install -D $downloadedFile $out/share/fonts/opentype/${pname}.otf
  '';

  sha256 = "sha256-focpDTofCAZx3ST3t3xlIrSk7NMqb+e+k00o+o4h5ig=";

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

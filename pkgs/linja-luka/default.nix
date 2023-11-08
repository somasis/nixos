{ lib, fetchurl }:

let
  pname = "linja-luka";
  version = "1.0";
  rev = "0f22e5a4beb5f0c577fdcc4e0f1995c64cefd547";
in
fetchurl {
  name = "${pname}-${version}";
  url =
    "https://github.com/janMelon/linja-luka/raw/${rev}/font-files/linja-luka-${version}.otf";

  downloadToTemp = true;
  recursiveHash = true;
  postFetch = ''
    install -D $downloadedFile $out/share/fonts/opentype/${pname}.otf
  '';

  sha256 = "sha256-dbF3LYAtyFV3oZ2Adi3TxQ8uURq6ckEfky51EDLxeeE=";

  meta = with lib; {
    description =
      "a handwriting-esque sitelen pona font, by jan Pensamin and jan Melon";
    homepage = "https://github.com/janMelon/linja-luka";
    license = licenses.ofl;
    platforms = platforms.all;
    maintainers = with maintainers; [ somasis ];
  };
}

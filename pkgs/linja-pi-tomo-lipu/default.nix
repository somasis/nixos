{ lib, fetchurl }:

let
  pname = "linja-pi-tomo-lipu";
  version = "0.7";
in
fetchurl {
  name = "${pname}-${version}";
  url =
    "https://github.com/pguimier/linjapitomolipu/releases/download/v${version}/linjapitomolipu.${version}.ttf";

  downloadToTemp = true;
  recursiveHash = true;
  postFetch = ''
    install -D $downloadedFile $out/share/fonts/opentype/${pname}.otf
  '';

  sha256 = "sha256-n36fcadrzZeJH2kublQO4jJdRUS0bBGGMWtCTxqhMI0=";

  meta = with lib; {
    description = "a monotype sitelen pona font adapted from tomo-lipu.net";
    homepage = "https://github.com/pguimier/linjapitomolipu";
    license = licenses.mit;
    platforms = platforms.all;
    maintainers = with maintainers; [ somasis ];
  };
}

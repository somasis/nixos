{ lib, fetchurl }:

let
  pname = "linja-pona";
  version = "4.9";
  rev = "8436d31ba84bb9c7198f7df2ec07d5b8b56ffdf7";
in
fetchurl {
  name = "${pname}-${version}";
  url =
    "https://github.com/janSame/${pname}/raw/${rev}/${pname}-${version}.otf";

  downloadToTemp = true;
  recursiveHash = true;
  postFetch = ''
    install -D $downloadedFile $out/share/fonts/opentype/${pname}.otf
  '';

  sha256 = "sha256-fDlr7AE+nZ/GG4me372uoEV4vIsOWkYpArpAnrO07Mo=";

  meta = with lib; {
    description = "a simple sitelen pona font by David A. Roberts and jan Same";
    homepage = "http://musilili.net/${pname}";
    downloadPage = "https://github.com/janSame/${pname}";
    license = licenses.ofl;
    platforms = platforms.all;
    maintainers = with maintainers; [ somasis ];
  };
}

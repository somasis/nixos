{ lib, fetchurl }:

let
  pname = "linja-suwi";
  version = "1.301";
  rev = "187fedaffbc5b2746ed77cf565f9af159bf7fe93";
in
fetchurl {
  name = "${pname}-${version}";
  url = "https://github.com/anna328p/linjasuwi/raw/${rev}/linjasuwi.otf";

  downloadToTemp = true;
  recursiveHash = true;
  postFetch = ''
    install -D $downloadedFile $out/share/fonts/opentype/${pname}.otf
  '';

  sha256 = "sha256-5KYid+Q/LuoYvTyMcf/j3pi3hNU44dpOBAoqmQtkpl8=";

  meta = with lib; {
    description = "a new sitelen pona font with a sweet look";
    homepage = "https://linjasuwi.ap5.dev";
    downloadPage = "https://github.com/anna328p/linjasuwi";
    license = licenses.ofl;
    platforms = platforms.all;
    maintainers = with maintainers; [ somasis ];
  };
}

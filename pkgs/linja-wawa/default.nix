{ lib, fetchurl }:

let
  pname = "linja-wawa";
  version = "1.21";
  rev = "52737d952f91eb046ecfef27d4245fa81d7c141f";
in
fetchurl {
  name = "${pname}-${version}";
  url =
    "https://github.com/janMelon/linjawawa/raw/${rev}/font-files/linjawawa${version}.otf";

  downloadToTemp = true;
  recursiveHash = true;
  postFetch = ''
    install -D $downloadedFile $out/share/fonts/opentype/${pname}.otf
  '';

  sha256 = "sha256-0HVRqHS8Ikzp32VclQJEb6nwpmW6b8nFrtHxh1v2OfM=";

  meta = with lib; {
    description =
      "a very bold font for Toki Pona's writing system, Sitelen Pona";
    homepage = "https://github.com/janMelon/linjawawa";
    license = licenses.ofl;
    platforms = platforms.all;
    maintainers = with maintainers; [ somasis ];
  };
}

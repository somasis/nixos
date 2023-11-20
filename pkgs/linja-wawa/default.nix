{ lib
, stdenvNoCC
, fetchurl
}:

let
  rev = "52737d952f91eb046ecfef27d4245fa81d7c141f";
in
stdenvNoCC.mkDerivation rec {
  pname = "linja-wawa";
  version = "1.21";

  src = fetchurl {
    url =
      "https://github.com/janMelon/linjawawa/raw/${rev}/font-files/linjawawa${version}.otf";
    hash = "sha256-0HVRqHS8Ikzp32VclQJEb6nwpmW6b8nFrtHxh1v2OfM=";
  };

  installPhase = ''
    install -D $src $out/share/fonts/opentype/${pname}.otf
  '';

  meta = with lib; {
    description =
      "a very bold font for the Toki Pona writing system, sitelen pona";
    homepage = "https://github.com/janMelon/linjawawa";
    license = licenses.ofl;
    platforms = platforms.all;
    maintainers = with maintainers; [ somasis ];
  };
}

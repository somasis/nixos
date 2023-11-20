{ lib
, stdenvNoCC
, fetchurl
}:

let
  rev = "8436d31ba84bb9c7198f7df2ec07d5b8b56ffdf7";
in
stdenvNoCC.mkDerivation rec {
  pname = "linja-pona";
  version = "4.9";

  src = fetchurl {
    url =
      "https://github.com/janSame/${pname}/raw/${rev}/${pname}-${version}.otf";
    hash = "sha256-wQfTK4b/S+N+YLdK83UCie2LquTQO44FhE45TEuXJcs=";
  };

  dontUnpack = true;

  installPhase = ''
    install -D $src $out/share/fonts/opentype/${pname}.otf
  '';

  meta = with lib; {
    description = "a simple sitelen pona font by David A. Roberts and jan Same";
    homepage = "http://musilili.net/${pname}";
    downloadPage = "https://github.com/janSame/${pname}";
    license = licenses.ofl;
    platforms = platforms.all;
    maintainers = with maintainers; [ somasis ];
  };
}

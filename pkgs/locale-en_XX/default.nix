{ lib
, fetchurl
, stdenvNoCC
}:
stdenvNoCC.mkDerivation rec {
  pname = "locale-en_xx";
  version = "2017";

  src = fetchurl {
    url = "${meta.homepage}/src/${pname}-${version}.tar.xz";
    hash = "sha256-tHnpczSat4jPuWe6G0Q12qouumXjlUMNb6rBKQvfIog=";
  };

  installPhase = ''
    install -Dm644 "en_XX@POSIX" $out/share/i18n/locales/en_XX@POSIX
  '';

  meta = with lib; {
    description = "A mixed international English locale with ISO and POSIX formats for cosmopolitan coders";
    homepage = "https://xyne.dev/projects/${pname}";
    license = licenses.gpl2;
    maintainers = with maintainers; [ somasis ];
    platforms = platforms.all;
  };
}

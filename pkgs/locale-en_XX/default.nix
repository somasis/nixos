{ lib
, fetchurl
, stdenvNoCC
,
}:
stdenvNoCC.mkDerivation rec {
  pname = "locale-en_xx";
  version = "2017";

  src = fetchurl {
    url = "https://xyne.dev/projects/locale-en_xx/src/locale-en_xx-2017.tar.xz";
    sha256 = "sha256-tHnpczSat4jPuWe6G0Q12qouumXjlUMNb6rBKQvfIog=";
  };

  installPhase = ''
    install -Dm644 "en_XX@POSIX" $out/share/i18n/locales/en_XX@POSIX
  '';

  meta = with lib; {
    description = "A mixed international English locale with ISO and POSIX formats for cosmopolitan coders";
    homepage = "https://xyne.dev/projects/locale-en_xx";
    license = licenses.gpl2;
    maintainers = with maintainers; [ somasis ];
    platforms = platforms.all;
  };
}

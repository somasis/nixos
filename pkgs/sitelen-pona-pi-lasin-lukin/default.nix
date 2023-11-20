{ lib
, stdenvNoCC
, fetchurl
}:

stdenvNoCC.mkDerivation rec {
  pname = "sitelen-pona-pi-lasin-lukin";
  version = "unstable-2023-11-05";

  src = fetchurl {
    url = "https://drive.google.com/uc?export=download&id=19ADcpE-EBAlBlE_ERLWN3ASzvTok1wfP";
    hash = "sha256-3Ew9MLLjiJ7qj04N2pjSH9FmqMu/CIS1sxDUAZxuCEs=";
  };

  dontUnpack = true;

  installPhase = ''
    install -D $src $out/share/fonts/truetype/${pname}.ttf
  '';

  meta = with lib; {
    homepage = "https://www.reddit.com/r/tokipona/comments/17oz1nz/a_romanstyled_sitelen_pona_font/";
    downloadPage = "https://drive.google.com/drive/folders/1WTarSAMNSf-96p24Xtcj7LJxoQmF71Aa?usp=drive_link";

    # license = licenses.unknown;
    platforms = platforms.all;
    maintainers = with maintainers; [ somasis ];
  };
}

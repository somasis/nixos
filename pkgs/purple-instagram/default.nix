{ lib
, stdenv
, fetchFromGitHub
, pidgin
, pkg-config
, glib
, json-glib
, zlib
}:
stdenv.mkDerivation rec {
  pname = "purple-instagram";
  version = "unstable-2019-11-21";

  src = fetchFromGitHub {
    owner = "EionRobb";
    repo = "purple-instagram";
    rev = "420cef45db2398739ac19c93640e6fff42865bb1";
    hash = "sha256-EbAVa5an6ZJ2aZUdPUKUehVZYhEi3g/52FpNAy6dx94=";
  };

  nativeBuildInputs = [ pkg-config ];
  buildInputs = [
    glib
    json-glib
    pidgin
    zlib
  ];

  makeFlags = [ "DESTDIR=$(out)" ];

  meta = with lib; {
    homepage = "https://github.com/EionRobb/purple-instagram";
    description = "Instagram protocol plugin for Pidgin";
    license = licenses.gpl3;
    platforms = platforms.linux;
  };
}

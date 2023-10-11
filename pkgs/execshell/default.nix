{ lib
, fetchFromGitHub
, skalibs
, execline
}:
stdenv.mkDerivation rec {
  pname = "execshell";
  version = "unstable-2020-11-01";

  src = fetchFromGitHub {
    owner = "sysvinit";
    repo = pname;
    rev = "b0b41d50cdb09f26b7f31e960e078c0500c661f5";
    hash = "sha256-TCk9U396NoZL1OvAddcMa2IFyvyDs/3daKv5IRxkRYE=";
    fetchSubmodules = true;
  };

  buildInputs = [ skalibs execline ];

  installPhase = ''
    install -m0755 -D execshell $out/bin/execshell
  '';

  makeFlags = [ "CC:=$(CC)" ];

  meta = with lib; {
    inherit (src.meta) homepage;
    description = "Proof of concept execline interactive REPL";
    license = with licenses; [ isc bsd2 ];
    maintainers = with maintainers; [ somasis ];
    platforms = platforms.unix;
  };
}

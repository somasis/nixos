{ lib
, stdenv
, fetchFromGitHub

, substituteAll

, xorg
}:
let inherit (xorg) libX11 xorgproto; in
stdenv.mkDerivation rec {
  pname = "xclickroot";
  version = "1.4.0";

  src = fetchFromGitHub {
    owner = "phillbush";
    repo = "xclickroot";
    rev = "v${version}";
    hash = "sha256-WuDQmujyggdv9tpj85dRc9FCom2qJFKTbjTFii1xlPo=";
  };

  makeFlags = [ "PREFIX=$(out)" ];

  configurePhase = ''
    substituteInPlace ./Makefile \
        --replace-fail ' -I''${LOCALINC}'   "" \
        --replace-fail ' -I''${X11INC}'     "" \
        --replace-fail ' -L''${LOCALLIB}'   "" \
        --replace-fail ' -L''${X11LIB}'     ""
    cat Makefile
  '';

  meta = with lib; {
    description = "Click on root window and run a command";
    homepage = "https://github.com/phillbush/xclickroot";
    license = licenses.mit;
    maintainers = with maintainers; [ somasis ];
    mainProgram = "xclickroot";
    platforms = platforms.all;
  };
}

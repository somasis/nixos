{ lib
, fetchFromGitHub
, iwd
, libnotify
, stdenvNoCC
,
}:
stdenvNoCC.mkDerivation rec {
  pname = "iwd-dmenu";
  version = "20211113";

  src = fetchFromGitHub {
    owner = "mlscarlson";
    repo = "${pname}";
    rev = "fc6cbb1b687d3120ca5896261d31b86d7ced8c95";
    sha256 = "sha256-9zoUb7wnwwQQ39IzNEd0K+xyUgw2vHIoe4mRHjA6Fj4==";
  };

  prePatch = ''
    substituteInPlace iwd-dmenu \
      --replace '| dmenu ' '| ''${DMENU:-dmenu} ' \
      --replace '$(dmenu ' '$(''${DMENU:-dmenu} ' \
      --replace 'herbe '   '${libnotify}/bin/notify-send "iwd" '
  '';

  runtimeInputs = [ iwd ];

  makeFlags = [ "PREFIX=$(out)" ];

  meta = with lib; {
    description = "An interactive iwd menu using dmenu";
    # homepage = "https://tools.suckless.org/dmenu";
    # license = licenses.mit;
    maintainers = with maintainers; [ somasis ];
    platforms = platforms.all;
  };
}

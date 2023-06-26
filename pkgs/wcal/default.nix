{ lib
, fetchFromGitHub
, stdenv
}:
stdenv.mkDerivation rec {
  pname = "wcal";
  version = "0.1";

  src = fetchFromGitHub {
    owner = "leahneukirchen";
    repo = pname;
    rev = "v${version}";
    hash = "sha256-jPD31Yn0rrZ5RiS09EcNwlBiG21p1s+SPFj67gswX7Y=";
  };

  makeFlags = [ "PREFIX=$(out)" ];

  meta = with lib; {
    description = "Print a week-oriented calendar";
    license = licenses.cc0;
    maintainers = with maintainers; [ somasis ];
  };
}

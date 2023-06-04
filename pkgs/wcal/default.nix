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
    hash = "sha256-eSz9zvHEFaE9QbmHP0C7m4TJ/bkYIahKjJqTf9AVghM=";
  };

  makeFlags = [ "PREFIX=$(out)" ];

  meta = with lib; {
    description = "Print a week-oriented calendar";
    license = licenses.cc0;
    maintainers = with maintainers; [ somasis ];
  };
}

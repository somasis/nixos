{ lib
, stdenv
, fetchFromGitHub
, cmake
, fcitx5
}:
stdenv.mkDerivation rec {
  pname = "fcitx5-ilo-sitelen";
  version = "unstable-2023-02-17";

  src = fetchFromGitHub {
    owner = "0x182d4454fb211940";
    repo = "ilo-sitelen";
    rev = "42be249c27efc21173984bf538e94ba5bb130695";
    hash = "sha256-caQVPBPuZjOwbtcDhxAdmG7PHXe50OeSLkSBoCtMcrQ=";
  };

  buildInputs = [ fcitx5 ];
  nativeBuildInputs = [ cmake ];

  meta = with lib; {
    description = "ilo sitelen kepeken sitelen pona";
    homepage = "https://github.com/0x182d4454fb211940/ilo-sitelen";
    license = licenses.mit;
    maintainers = with maintainers; [ somasis ];
  };
}

{ lib
, fetchFromGitHub
, kakouneUtils
}:
kakouneUtils.buildKakounePluginFrom2Nix rec {
  pname = "tug";
  version = "unstable-2020-02-22";

  src = fetchFromGitHub {
    repo = pname;
    owner = "matthias-margush";
    rev = "23adaadb795af2d86dcb3daf7af3ebe12e932441";
    hash = "sha256-cW11DPsjBBtjOfU9gizH8dGSV3B1rQiD0qeO/Ab8jWI=";
  };

  meta = with lib; {
    inherit (src.meta) homepage;
    maintainers = with maintainers; [ somasis ];
    description = "Easily access file management commands from inside Kakoune";
  };
}

{ lib
, fetchFromGitHub
, fcitx5
, kakouneUtils
}:
kakouneUtils.buildKakounePluginFrom2Nix rec {
  pname = "kakoune-fcitx";
  version = "unstable-2018-08-28";

  src = fetchFromGitHub {
    owner = "h-youhei";
    repo = pname;
    rev = "2e8ed9a19a997cd779df0f56aff8055af315516c";
    hash = "sha256-fI1TprgMitAhWMn09tMTqVbA2BvDye3K6oMN3O2IMbw=";
  };

  meta = with lib; {
    inherit (src.meta) homepage;
    maintainers = with maintainers; [ somasis ];
    license = licenses.unlicense;
    inherit (fcitx5.meta) platforms;
  };
}

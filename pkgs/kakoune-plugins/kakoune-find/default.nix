{ lib
, fetchFromGitHub
, kakouneUtils
}:
kakouneUtils.buildKakounePluginFrom2Nix rec {
  pname = "kakoune-find";
  version = "unstable-2022-09-25";

  src = fetchFromGitHub {
    repo = pname;
    owner = "occivink";
    rev = "09afcc8520d4c92928fe69da4c370b9979aa90d3";
    hash = "sha256-AyG0AbQOTFDQ/jrhtyb5ajWlvWO+h0JDe5SEtTyTkfQ=";
  };

  meta = with lib; {
    inherit (src.meta) homepage;
    maintainers = with maintainers; [ somasis ];
    description = "Find and replace strings across open buffers";
  };
}

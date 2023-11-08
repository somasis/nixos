{ lib
, fetchFromGitHub
, kakouneUtils
}:
kakouneUtils.buildKakounePluginFrom2Nix rec {
  pname = "csv-kak";
  version = "unstable-2020-05-29";

  src = fetchFromGitHub {
    owner = "gspia";
    repo = "csv.kak";
    rev = "00d0c4269645e15c8f61202e265328c470cd85c2";
    hash = "sha256-3Y7J9ctuA9kyn8tlKTkxQiwXuglsWC54gaKtB1m3DA4=";
  };

  meta = with lib; {
    inherit (src.meta) homepage;
    maintainers = with maintainers; [ somasis ];
    description = "Syntax highlighting from comma-separated-value files";
  };
}

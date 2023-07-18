{ config
, pkgs
, ...
}: {
  programs.kakoune = {
    plugins = [
      (pkgs.kakouneUtils.buildKakounePluginFrom2Nix {
        pname = "csv-kak";
        version = "unstable-2020-05-29";
        src = pkgs.fetchFromGitHub {
          owner = "gspia";
          repo = "csv.kak";
          rev = "00d0c4269645e15c8f61202e265328c470cd85c2";
          hash = "sha256-3Y7J9ctuA9kyn8tlKTkxQiwXuglsWC54gaKtB1m3DA4=";
        };
      })
    ];

    config.hooks = [{
      name = "BufCreate";
      option = ".*\.tsv";
      commands = ''
        set-option buffer csv_sep "\t"
        set-option buffer filetype csv
      '';
    }];
  };
}

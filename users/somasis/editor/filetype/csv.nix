{ config
, pkgs
, ...
}: {
  programs.kakoune = {
    plugins = [ pkgs.kakounePlugins.csv-kak ];

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

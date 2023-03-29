{ config
, pkgs
, ...
}: {
  home.persistence."/persist${config.home.homeDirectory}".directories = [{
    method = "symlink";
    directory = "diary";
  }];
  home.packages = [
    (pkgs.writeShellScriptBin "diary" ''
      exec ''${EDITOR:-vi} "$HOME/diary/$(date +%Y/%m/%d.txt)"
    '')
  ];
}

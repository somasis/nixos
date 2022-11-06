{ config
, pkgs
, ...
}: {
  home.persistence."/persist${config.home.homeDirectory}".directories = [ "diary" ];
  home.packages = [
    (pkgs.writeShellScriptBin "diary" ''
      exec ''${EDITOR:-editor} "$HOME/diary/$(date +%Y/%m/%d.txt)"
    '')
  ];
}

{ pkgs, config, ... }: {
  home.packages = [ pkgs.urbanterror ];
  home.persistence."/persist${config.home.homeDirectory}".directories = [ ".q3a" ];
}

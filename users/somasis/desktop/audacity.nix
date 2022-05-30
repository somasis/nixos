{ pkgs, config, ... }: {
  home.packages = [ pkgs.audacity ];
  home.persistence."/persist${config.home.homeDirectory}".directories = [ "etc/audacity" ];
}

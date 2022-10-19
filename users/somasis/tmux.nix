{ config
, pkgs
, ...
}: {
  home.packages = [ pkgs.tmux ];
  home.persistence."/persist${config.home.homeDirectory}".directories = [ "etc/tmux" ];
}

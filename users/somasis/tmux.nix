{ config
, pkgs
, ...
}: {
  # TODO: manage tmux via home-manager
  home.packages = [ pkgs.tmux ];
  home.persistence."/persist${config.home.homeDirectory}".directories = [ "etc/tmux" ];
}

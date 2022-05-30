{ config, pkgs, ... }: {
  home.persistence."/persist${config.home.homeDirectory}".directories = [ "ledger" ];

  home.packages = [ pkgs.ledger ];
}

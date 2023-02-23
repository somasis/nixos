{ config, ... }: {
  imports = [
    ./citation.nix
    ./editing.nix
    ./reading.nix
    ./writing.nix
  ];

  home.persistence."/persist${config.home.homeDirectory}".directories = [ "study" ];
  xdg.userDirs.documents = "${config.home.homeDirectory}/study/current";
}

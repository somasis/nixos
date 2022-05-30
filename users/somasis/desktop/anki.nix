{ pkgs, config, ... }: {
  home.packages = [ pkgs.anki ];
  home.persistence."/persist${config.home.homeDirectory}".directories = [
    "share/Anki"
    "share/Anki2"
  ];
}

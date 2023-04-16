{ pkgs, config, ... }: {
  home.packages = [ pkgs.anki ];
  home.persistence."/persist${config.home.homeDirectory}".directories = [
    { directory = "share/Anki"; method = "symlink"; }
    { directory = "share/Anki2"; method = "symlink"; }
  ];
}

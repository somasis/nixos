{ pkgs, config, ... }: {
  home.packages = [ pkgs.anki ];
  home.persistence."/persist${config.home.homeDirectory}".directories = [
    { method = "symlink"; directory = "share/Anki"; }
    { method = "symlink"; directory = "share/Anki2"; }
  ];
}

{ pkgs, config, ... }: {
  home.packages = [ pkgs.anki-bin ];
  persist.directories = [
    { method = "symlink"; directory = config.lib.somasis.xdgDataDir "Anki"; }
    { method = "symlink"; directory = config.lib.somasis.xdgDataDir "Anki2"; }
  ];
}

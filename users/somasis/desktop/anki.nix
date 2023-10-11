{ pkgs, config, ... }: {
  home.packages = [ pkgs.anki-bin ];
  persist.directories = [
    { method = "symlink"; directory = "share/Anki"; }
    { method = "symlink"; directory = "share/Anki2"; }
  ];
}

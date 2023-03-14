{ config, ... }: {
  imports = [
    ./citation.nix
    ./editing.nix
    ./reading.nix
    ./writing.nix
  ];

  home.persistence."/persist${config.home.homeDirectory}".directories = [
    { directory = "study"; method = "symlink"; }
  ];

  xdg.userDirs.documents = "${config.home.homeDirectory}/study/current";

  programs.zotero.profiles.default.settings = {
    "extensions.zotero.dataDir" = "${config.xdg.dataHome}/zotero";

    # ZotFile > General Settings > "Location of Files"
    "extensions.zotfile.dest_dir" = "${config.home.homeDirectory}/study/doc";
  };
}

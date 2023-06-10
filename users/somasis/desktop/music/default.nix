{ config
, ...
}: {
  imports = [
    ../../music/manage

    ./cantata.nix
    ./daemon.nix
    ./player.nix
    ./random.nix
    ./scrobble.nix
  ];

  xdg.userDirs.music = "${config.home.homeDirectory}/audio/library";
  persist.directories = [{ method = "bindfs"; directory = "audio"; }];
}

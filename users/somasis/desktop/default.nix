{ inputs
, lib
, pkgs
, config
, osConfig
, ...
}: {
  imports = [
    # ./cinnamon.nix
    # ./gnome.nix
    # ./kde.nix
    # ./wayland.nix
    # ./xterm.nix

    ./browser
    ./chat
    ./feeds
    ./games
    ./mail
    ./music
    ./panel
    ./pim
    ./study
    ./stw

    ./anki.nix
    ./audio.nix
    ./automount.nix
    ./clipboard.nix
    ./dates.nix
    ./diary.nix
    ./didyouknow.nix
    ./display.nix
    ./dmenu.nix
    ./file-manager.nix
    ./ledger.nix
    ./list.nix
    ./mess.nix
    ./mounts.nix
    ./mouse.nix
    ./notifications.nix
    ./phone.nix
    ./photo.nix
    ./power.nix
    ./screen-brightness.nix
    ./screen-locker.nix
    ./screen-temperature.nix
    ./sxhkd.nix
    ./syncplay.nix
    ./syncthing.nix
    ./terminal.nix
    ./theme.nix
    ./torrent.nix
    ./video.nix
    ./wallpaper.nix
    ./window-manager.nix
    ./wine.nix
    ./www.nix
  ];

  home.extraOutputsToInstall = [ "doc" "devdoc" "man" ];

  log.directories = [{ method = "symlink"; directory = "logs"; }];

  home.packages = [
    pkgs.bc
    pkgs.bmake
    pkgs.ffmpeg-full
    pkgs.gnome.zenity
    pkgs.hyperfine
    pkgs.nurl
    pkgs.xcolor
    pkgs.xorg.xinput
    pkgs.xzoom
  ];

  home.file = {
    ".face".source = inputs.avatarSomasis;
    ".face.png".source = inputs.avatarSomasis;
  };

  xsession = {
    enable = true;
    importedVariables = lib.mkBefore [ "PATH" ];

    # Necessary so that `startx` runs home-manager's managed xsession
    scriptPath = ".xinitrc";

    profilePath = "etc/xorg/xprofile";
  };

  xresources.path = "${config.xdg.configHome}/xorg/xresources";

  services.xsuspender = {
    # Basically disable xsuspender by default; only enable for certain programs.
    enable = config.services.xsuspender.rules != { };
    defaults = {
      resumeEvery = 0;
      suspendDelay = 0;
      onlyOnBattery = false;
      autoSuspendOnBattery = false;
    };

    debug = true;
  };

  somasis.tunnels.enable = true;
}

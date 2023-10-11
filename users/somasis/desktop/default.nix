{ inputs
, pkgs
, config
, osConfig
, lib
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
    ./compositing.nix
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
    (pkgs.stdenv.mkDerivation rec {
      pname = "execshell";
      version = "20201101";

      src = pkgs.fetchFromGitHub {
        owner = "sysvinit";
        repo = "execshell";
        rev = "b0b41d50cdb09f26b7f31e960e078c0500c661f5";
        hash = "sha256-TCk9U396NoZL1OvAddcMa2IFyvyDs/3daKv5IRxkRYE=";
        fetchSubmodules = true;
      };

      buildInputs = [ pkgs.skalibs pkgs.execline ];

      installPhase = ''
        install -m0755 -D execshell $out/bin/execshell
      '';

      makeFlags = [ "CC:=$(CC)" ];

      meta = with pkgs.lib; {
        description = "Proof of concept execline interactive REPL";
        license = with licenses; [ isc bsd2 ];
        maintainers = with maintainers; [ somasis ];
        platforms = platforms.all;
      };
    })

    pkgs.bc
    pkgs.bmake
    pkgs.ffmpeg-full
    pkgs.gnome.zenity
    pkgs.hyperfine
    pkgs.mmutils
    pkgs.nurl
    pkgs.wmutils-core
    pkgs.wmutils-opt
    pkgs.xcolor
    pkgs.xdragon
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

  i18n.inputMethod = {
    enabled = "fcitx5";
    fcitx5.addons = [
      pkgs.fcitx5-anthy
      pkgs.fcitx5-gtk
      pkgs.libsForQt5.fcitx5-qt
      pkgs.fcitx5-mozc
    ];
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

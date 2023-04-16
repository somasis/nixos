{ inputs
, pkgs
, config
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
    ./games
    ./mail
    ./pim
    ./study
    ./stw

    ./anki.nix
    ./automount.nix
    ./autorandr.nix
    ./clipboard.nix
    ./compositing.nix
    ./dates.nix
    ./diary.nix
    ./dmenu.nix
    ./feeds.nix
    ./file-manager.nix
    ./fonts.nix
    ./ledger.nix
    ./list.nix
    ./mess.nix
    ./mounts.nix
    ./mouse.nix
    ./music.nix
    ./notifications.nix
    ./panel.nix
    ./phone-integration.nix
    ./photo.nix
    ./power.nix
    ./screen-brightness.nix
    ./screen-locker.nix
    ./screen-temperature.nix
    ./syncthing.nix
    ./sxhkd.nix
    ./syncplay.nix
    ./terminal.nix
    ./theme.nix
    ./torrent.nix
    ./video.nix
    ./wallpaper.nix
    ./window-manager.nix
    ./wine.nix
  ];

  home.extraOutputsToInstall = [ "doc" "devdoc" "man" ];

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

    (pkgs.writeShellScriptBin "ponymix-snap" ''
      snap=5
      [ "$FLOCKER" != "$0" ] \
          && export FLOCKER="$0" \
          && exec flock -n "$0" "$0" "$@"

      ${pkgs.ponymix}/bin/ponymix "$@"
      b=$(${pkgs.ponymix}/bin/ponymix --short get-volume)
      c=$((b - $((b % snap))))
      ${pkgs.ponymix}/bin/ponymix --short set-volume "$c" >/dev/null
    '')

    pkgs.asciidoctor
    pkgs.bc
    pkgs.bmake
    pkgs.ffmpeg-full
    pkgs.gnome.zenity
    pkgs.lowdown
    pkgs.mmutils
    pkgs.patchutils
    pkgs.wmutils-core
    pkgs.wmutils-opt
    pkgs.xcolor
    pkgs.xdragon
    pkgs.xmlstarlet
    pkgs.xorg.xinput
    pkgs.xzoom
    pkgs.hyperfine
    pkgs.nurl

    (pkgs.libsForQt5.callPackage
      ({ stdenv
       , fetchFromGitHub
       , cmake
       , pkg-config
       , qtbase
       , qttools
       , wrapQtAppsHook
       , fmt
       , libpsl
       , cxxopts
       , httplib
       , gettext
       , openssl
       , kwidgetsaddons
       , kwindowsystem
       }:
        stdenv.mkDerivation rec {
          pname = "tremotesf2";
          version = "2.1.0";

          src = fetchFromGitHub {
            owner = "equeim";
            repo = pname;
            rev = version;
            hash = "sha256-xnBrBtj1AjhVKVsxsGZ85y2cX6B/3ZCJXRegRwb0xC0=";
            fetchSubmodules = true;
          };

          nativeBuildInputs = [ pkg-config cmake qttools wrapQtAppsHook ];
          buildInputs = [ qtbase fmt kwidgetsaddons libpsl cxxopts ]
            ++ lib.optionals stdenv.hostPlatform.isUnix [ gettext kwindowsystem ];
          checkInputs = [ qtbase openssl httplib ];

          cmakeFlags = [ "-DPKG_CONFIG_EXECUTASBLE=${pkg-config}/bin/pkg-config" ];

          meta = with lib; {
            description = "Remote GUI for transmission-daemon";
            homepage = "https://github.com/equeim/tremotesf2";
            license = with licenses; [ cc0 gpl3Plus mit lgpl21Plus gpl2Plus ]; # cc-by-nd-40 lgpl20Only
            maintainers = [ maintainers.somasis ];
            platforms = platforms.unix ++ platforms.windows;
          };
        })
      { })

    (pkgs.callPackage ../../../pkgs/youplot { })
  ];

  # home.file.".face".source = "${inputs.avatarSomasis}";

  xsession = {
    enable = true;
    importedVariables = lib.mkBefore [ "PATH" ];
  };

  # Necessary so that `startx` runs home-manager's managed xsession
  xsession.scriptPath = ".xinitrc";

  xresources.path = "${config.xdg.configHome}/xorg/xresources";
  xsession.profilePath = "etc/xorg/xprofile";

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


  somasis = {
    chrome.stw.enable = true;

    tunnels = {
      enable = true;
      tunnels = [{
        name = "kodi";
        location = 45780;
        remote = "somasis@spinoza.7596ff.com";
        remoteLocation = 8080;
      }];
    };
  };
}

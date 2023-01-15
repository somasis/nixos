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

    ./games
    ./mail
    ./pim
    ./qutebrowser
    ./stw

    ./anki.nix
    ./audacity.nix
    ./automount.nix
    ./autorandr.nix
    ./clipboard.nix
    ./compositing.nix
    ./dates.nix
    ./diary.nix
    ./discord.nix
    ./dmenu.nix
    ./feeds.nix
    ./file-manager.nix
    ./fonts.nix
    ./irc.nix
    ./ledger.nix
    ./list.nix
    ./mess.nix
    ./mounts.nix
    ./mouse.nix
    ./music.nix
    ./notifications.nix
    ./office.nix
    ./panel.nix
    ./pdf.nix
    ./phone-integration.nix
    ./photo.nix
    ./picom.nix
    ./power.nix
    ./screen-brightness.nix
    ./screen-locker.nix
    ./screen-temperature.nix
    ./study.nix
    ./sxhkd.nix
    ./syncplay.nix
    ./terminal.nix
    ./theme.nix
    ./torrent.nix
    ./tunnels.nix
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
    pkgs.poedit
    pkgs.wmutils-core
    pkgs.wmutils-opt
    pkgs.xcolor
    pkgs.xdragon
    pkgs.xmlstarlet
    pkgs.xorg.xinput
    pkgs.xzoom
    pkgs.hyperfine
  ];


  home.persistence."/persist${config.home.homeDirectory}".directories = [ "etc/poedit" ];

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
    enable = true;
    debug = true;

    # Basically disable xsuspender by default; only enable for certain programs.
    defaults = {
      resumeEvery = 0;
      suspendDelay = 0;
      onlyOnBattery = false;
      autoSuspendOnBattery = false;
    };
  };

  somasis.chrome.stw.enable = true;
}

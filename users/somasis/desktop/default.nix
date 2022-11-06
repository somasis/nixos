{ inputs, pkgs, config, lib, ... }: {
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
    ./bspwm.nix
    ./clipboard.nix
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
    ./wine.nix
  ];

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
  ];


  home.persistence."/persist${config.home.homeDirectory}".directories = [ "etc/poedit" ];

  # home.file.".face".source = "${inputs.avatarSomasis}";

  systemd.user.targets.root-windows = {
    Unit.Description = "All services that put information on the desktop";
    # Install.WantedBy = [ "graphical-session.target" ];
    # Unit.PartOf = [ "graphical-session.target" ];
  };

  # HACK(?): root-windows.target is triggered by bspwm's configuration
  #          file because we can know for sure that the Xresources have
  #          been read in by the point bspwm is being ran.
  #
  #          However, maybe hm-graphical-session.target should actually
  #          run only after `xrdb -merge` is executed...?
  xsession = {
    enable = true;
    importedVariables = lib.mkBefore [ "PATH" ];

    windowManager.bspwm.extraConfig = lib.mkAfter ''
      ${pkgs.systemd}/bin/systemctl --user start --all root-windows.target
    '';
  };

  # Necessary so that `startx` runs home-manager's managed xsession
  xsession.scriptPath = ".xinitrc";

  xresources.path = "${config.xdg.configHome}/xorg/xresources";
  xsession.profilePath = "etc/xorg/xprofile";

  services.sxhkd.keybindings = {
    "super + F1" = ''
      ${pkgs.systemd}/bin/systemctl --user -q is-active --all root-windows.target \
          && ${pkgs.systemd}/bin/systemctl --user stop --all root-windows.target \
          || ${pkgs.systemd}/bin/systemctl --user start --all root-windows.target
    '';

    "super + shift + F1" = ''
      ${pkgs.systemd}/bin/systemctl --user list-dependencies --plain --state=active root-windows.target \
          | sed '/\.service$/!d; s/^ *//' \
          | ${pkgs.xe}/bin/xe -vN0 ${pkgs.systemd}/bin/systemctl --user reload 2>/dev/null
    '';
  };
}

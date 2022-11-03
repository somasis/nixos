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
    ./catgirl.nix
    ./clipboard.nix
    ./dates.nix
    ./discord.nix
    ./dmenu.nix
    ./feeds.nix
    ./file-manager.nix
    ./fonts.nix
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
    ./pubs.nix
    ./screen-brightness.nix
    ./screen-locker.nix
    ./screen-temperature.nix
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

    pkgs.xdragon
    pkgs.gnome.zenity

    pkgs.xzoom
    pkgs.xcolor
    pkgs.xorg.xinput
    pkgs.asciidoctor
    pkgs.bmake
    pkgs.lowdown
    pkgs.patchutils
    pkgs.bc
    pkgs.bmake
    pkgs.poedit

    pkgs.xmlstarlet

    pkgs.ffmpeg-full
  ];


  home.persistence."/persist${config.home.homeDirectory}".directories = [ "etc/poedit" ];

  home.file.".face".source = "${inputs.avatarSomasis}";

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

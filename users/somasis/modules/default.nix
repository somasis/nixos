{ lib
, config
, pkgs
, ...
}:
with lib;
{
  imports = [
    ./panel

    ./dmenu.nix
    ./stw.nix
    ./tunnels.nix
    ./zotero.nix
  ];

  config = mkIf config.services.stw.enable {
    systemd.user.targets.graphical-session-post = {
      Unit = {
        Description = "All services that ought to run after the graphical session is initialized";
        After = [ "picom.service" ];
      };

      # HACK(?): graphical-session-post.target is triggered by bspwm's configuration
      #          file because we can know for sure that the Xresources have
      #          been read in by the point bspwm is being ran.
      #
      #          However, maybe hm-graphical-session.target should actually
      #          run only after `xrdb -merge` is executed...?
      # Unit.PartOf = [ "graphical-session.target" ];
      # Install.WantedBy = [ "graphical-session.target" ];
    };

    xsession.windowManager.bspwm.extraConfig = lib.mkAfter ''
      ${pkgs.systemd}/bin/systemctl --user start --all graphical-session-post.target
    '';

    services.sxhkd.keybindings = {
      "super + F1" = ''
        ${pkgs.systemd}/bin/systemctl --user -q is-active --all graphical-session-post.target \
            && ${pkgs.systemd}/bin/systemctl --user stop --all graphical-session-post.target \
            || ${pkgs.systemd}/bin/systemctl --user start --all graphical-session-post.target
      '';

      "super + shift + F1" = ''
        ${pkgs.systemd}/bin/systemctl --user list-dependencies --plain --state=active graphical-session-post.target \
            | ${pkgs.gnused}/bin/sed '/\.service$/!d; s/^ *//' \
            | ${pkgs.xe}/bin/xe -N0 ${pkgs.systemd}/bin/systemctl --user reload 2>/dev/null
      '';
    };
  };
}

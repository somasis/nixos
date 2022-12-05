{ lib
, config
, pkgs
, ...
}:
with lib;
let cfg = config.somasis.chrome; in
{
  imports = [
    ./stw.nix
  ];

  config = mkIf (cfg.stw.enable) {
    systemd.user.targets.chrome = {
      Unit = {
        Description = "All services that put something on the screeen supplementary to the desktop";
        After = [ "picom.service" ];
      };

      # HACK(?): chrome.target is triggered by bspwm's configuration
      #          file because we can know for sure that the Xresources have
      #          been read in by the point bspwm is being ran.
      #
      #          However, maybe hm-graphical-session.target should actually
      #          run only after `xrdb -merge` is executed...?
      # Unit.PartOf = [ "graphical-session.target" ];
      # Install.WantedBy = [ "graphical-session.target" ];
    };

    xsession.windowManager.bspwm.extraConfig = lib.mkAfter ''
      ${pkgs.systemd}/bin/systemctl --user start --all chrome.target
    '';

    services.sxhkd.keybindings = {
      "super + F1" = ''
        ${pkgs.systemd}/bin/systemctl --user -q is-active --all chrome.target \
            && ${pkgs.systemd}/bin/systemctl --user stop --all chrome.target \
            || ${pkgs.systemd}/bin/systemctl --user start --all chrome.target
      '';

      "super + shift + F1" = ''
        ${pkgs.systemd}/bin/systemctl --user list-dependencies --plain --state=active chrome.target \
            | ${pkgs.gnused}/bin/sed '/\.service$/!d; s/^ *//' \
            | ${pkgs.xe}/bin/xe -N0 ${pkgs.systemd}/bin/systemctl --user reload 2>/dev/null
      '';
    };

  };
}

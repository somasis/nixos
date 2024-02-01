{ config
, pkgs
, lib
, osConfig
, ...
}:
let
  hook = pkgs.writeShellScript "autorandr-hook" ''
    ${pkgs.autorandr}/bin/autorandr "$@"
  '';
in
{
  # home.activation."autorandr" = ''
  #   if [ -n "''${DISPLAY:-}" ] \
  #       && ${pkgs.systemd}/bin/systemctl --user is-active -q graphical-session.target >/dev/null \
  #       && [ "$($DRY_RUN_CMD ${hook} --detected)" != "$($DRY_RUN_CMD ${hook} --current)" ]; then
  #       $DRY_RUN_CMD ${hook} -c || :
  #   fi
  #   exit
  # '';

  systemd.user.services.xsecurelock.Service.ExecStopPost = [ "-${hook} -c" ];
  services.sxhkd.keybindings."super + p" = "${hook} --cycle";

  # Use extraConfig because startupPrograms forks the program,
  # and we want autorandr to run before startup programs
  xsession.windowManager.bspwm.extraConfig = lib.mkBefore "${hook} -c";

  # Match exclusively based on the fingerprint rather than the display name.
  # The EDID can change based on the location that an expansion port ends up on the USB bus.
  # xdg.configFile."autorandr/settings.ini".text = pkgs.generators.toINI { } {
  #   config.match-edid = true;
  # };

  programs.autorandr.enable = true;
}

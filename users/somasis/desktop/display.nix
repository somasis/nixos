{ config
, pkgs
, lib
, osConfig
, ...
}:
let
  # using writeShellScriptBin because, if this is from a systemd service,
  # systemd will use the full path with Nix store hash and all in the
  # syslog identifier, which looks a bit ugly and is unnecessary
  hook = (pkgs.writeShellScriptBin "autorandr-hook" "${pkgs.autorandr}/bin/autorandr \"$@\"") + "/bin/autorandr-hook";
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

  programs.autorandr.enable = true;
  services.autorandr = {
    enable = true;
    ignoreLid = osConfig.services.autorandr.ignoreLid or true;
  };

  systemd.user.services.autorandr = lib.mkIf osConfig.services.autorandr.enable (
    let osService = osConfig.systemd.services.autorandr; in lib.mkForce {
      Unit = osService.unitConfig;

      # following <nixpkgs/nixos/lib/systemd-lib.nix>
      Install.WantedBy = osService.wantedBy;

      # really makes me appreciate how home-manager does systemd options
      Service = {
        Environment =
          lib.mapAttrsToList (n: v: "${n}=${builtins.toJSON v}")
            (osConfig.systemd.globalEnvironment // osService.environment)
        ;
      } // osService.serviceConfig
      ;
    }
  );
}

{ pkgs
, config
, lib
, osConfig
, ...
}: {
  services.sctd = {
    enable = true;
    baseTemperature = 3900;
  };

  systemd.user.services = {
    xsecurelock.Service = {
      ExecStartPost = [ "-${pkgs.systemd}/bin/systemctl --user stop sctd.service" ];
      ExecStopPost = [ "-${pkgs.systemd}/bin/systemctl --user start sctd.service" ];
    };

    sctd.Unit = {
      After = [ "game.target" "xiccd.service" ];
      Conflicts = [ "game.target" ];
    };
  };

  programs.autorandr.hooks.postswitch.screen-temperature = ''
    ${lib.toShellVar "machine" osConfig.networking.fqdnOrHostName}

    case "$AUTORANDR_CURRENT_PROFILE" in
        "$machine"[:+]"tv")
            ${pkgs.systemd}/bin/systemctl --user stop sctd.service
            ;;
        "$machine"|"$machine"[:+]*)
            ${pkgs.systemd}/bin/systemctl --user try-restart sctd.service
            ;;
    esac
  '';
}

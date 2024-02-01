{ pkgs, osConfig, ... }: {
  services.sctd = {
    enable = true;
    baseTemperature = 3900;
  };

  systemd.user.services = {
    xsecurelock.Service = {
      ExecStartPost = [ "-${pkgs.systemd}/bin/systemctl --user stop sctd.service" ];
      ExecStopPost = [ "-${pkgs.systemd}/bin/systemctl --user start sctd.service" ];
    };

    sctd.Unit.After = [ "xiccd.service" ];
  };

  programs.autorandr.hooks.postswitch.sctd = ''
    # f="${osConfig.networking.fqdnOrHostName}"

    # case "$AUTORANDR_CURRENT_PROFILE" in
    #     "$f"[:+]"tv")
    #         ${pkgs.systemd}/bin/systemctl --user stop sctd.service
    #         ;;
    #     "$f"|"$f"[:+]*)
            ${pkgs.systemd}/bin/systemctl --user try-restart sctd.service
    #         ;;
    # esac
  '';
}

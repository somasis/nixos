{ pkgs, nixosConfig, ... }: {
  services.sctd = {
    enable = true;
    baseTemperature = 3900;
  };

  systemd.user.services.xsecurelock.Service.ExecStartPre = [
    "-${pkgs.systemd}/bin/systemctl --user stop sctd.service"
  ];

  systemd.user.services.xsecurelock.Service.ExecStopPost = [
    "-${pkgs.systemd}/bin/systemctl --user start sctd.service"
  ];

  programs.autorandr.hooks.postswitch."sctd" = ''
    f="${nixosConfig.networking.fqdn}"

    case "$AUTORANDR_CURRENT_PROFILE" in
        "$f"[:+]"tv")
            ${pkgs.systemd}/bin/systemctl --user stop sctd.service
            ;;
        "$f"|"$f"[:+]*)
            ${pkgs.systemd}/bin/systemctl --user try-restart sctd.service
            ;;
    esac
  '';
}

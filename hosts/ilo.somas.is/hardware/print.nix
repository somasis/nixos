{ pkgs, ... }: {
  services.printing = {
    enable = true;
    browsing = true;

    drivers = [ pkgs.hplip ];
  };

  # Necessary for discovering printers on the network.
  # CUPS doesn't use systemd-resolved for discovery.
  # <https://github.com/apple/cups/issues/5452>
  services.avahi = {
    enable = true;
    nssmdns4 = true;
  };

  cache.directories = [ "/var/cache/cups" ];
  log.directories = [ "/var/log/cups" ];

  networking.networkmanager.dispatcherScripts = [{
    type = "basic";
    source = pkgs.writeText "restart-avahi" ''
      [ "$2" = "up" ] \
          && ${pkgs.systemd}/bin/systemctl try-restart avahi-daemon.service
    '';
  }];
}

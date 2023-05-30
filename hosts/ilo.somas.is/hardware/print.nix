{ pkgs, ... }: {
  services.printing = {
    enable = true;
    browsing = true;
  };

  # Necessary for discovering printers on the network.
  # CUPS doesn't use systemd-resolved for discovery.
  # <https://github.com/apple/cups/issues/5452>
  services.avahi = {
    enable = true;
    nssmdns = true;
  };

  cache.directories = [ "/var/cache/cups" ];
  log.directories = [ "/var/log/cups" ];
}

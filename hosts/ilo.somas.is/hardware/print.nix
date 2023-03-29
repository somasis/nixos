{ pkgs, ... }: {
  services.printing = {
    enable = true;
    browsing = true;
    drivers = [ pkgs.gutenprint ];
  };

  # Necessary for discovering printers on the network.
  # CUPS doesn't use systemd-resolved for discovery.
  # <https://github.com/apple/cups/issues/5452>
  services.avahi = {
    enable = true;
    nssmdns = true;
  };

  environment.persistence."/cache".directories = [ "/var/cache/cups" ];
  environment.persistence."/log".directories = [ "/var/log/cups" ];
}

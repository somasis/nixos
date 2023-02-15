{ pkgs, ... }: {
  services.printing = {
    enable = true;

    browsing = true;

    drivers = [
      pkgs.gutenprint
      # pkgs.brlaser
      # pkgs.hplip
    ];
  };

  # Necessary for discovering printers on the network.
  services.avahi = {
    enable = true;
    nssmdns = true;
  };

  environment.persistence."/cache".directories = [ "/var/cache/cups" ];
  environment.persistence."/log".directories = [ "/var/log/cups" ];
}

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

  persist.directories = [{
    mode = "0755";
    directory = "/var/lib/cups";
  }];

  cache.directories = [
    { mode = "0770"; user = "root"; group = "lp"; directory = "/var/cache/cups"; }
    { mode = "0710"; user = "root"; group = "lp"; directory = "/var/spool/cups"; }
  ];

  log.directories = [{
    mode = "0755";
    user = "root";
    group = "lp";
    directory = "/var/log/cups";
  }];

  networking.networkmanager.dispatcherScripts = [{
    type = "basic";
    source = pkgs.writeText "restart-avahi" ''
      if [ "$2" = "up" ]; then
          ${pkgs.systemd}/bin/systemctl try-restart avahi-daemon.service
      fi
    '';
  }];

  # this seems to fix some discovery issues for me?
  # systemd.services.cups-browsed = {
  #   wants = [ "cups.service" ];
  #   after = [ "cups.service" ];
  # };
}

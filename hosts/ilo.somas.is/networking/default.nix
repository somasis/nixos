{ config
, pkgs
, lib
, ...
}: {
  # imports = [ ./ipfs.nix ];

  networking = {
    hostName = "ilo";
    domain = "somas.is";

    hostId = builtins.substring 0 8 (builtins.hashString "sha256" config.networking.fqdnOrHostName);

    useDHCP = false;

    # Necessary for Syncthing.
    firewall.allowedTCPPorts = [ 22000 21027 ];
    firewall.allowedUDPPorts = [ 22000 ];

    # Necessary for KDE Connect
    firewall.allowedTCPPortRanges = [
      { from = 1714; to = 1764; }
    ];
    firewall.allowedUDPPortRanges = [
      { from = 1714; to = 1764; }
    ];

    networkmanager = {
      enable = true;

      ethernet.macAddress = "stable";
      wifi = {
        macAddress = "random";
        powersave = true;
      };
    };
  };

  persist.directories = [ "/etc/NetworkManager/system-connections" ];
  cache.directories = [ "/var/lib/NetworkManager" ];

  # TODO: Track net usage by services
  #       Currently cannot by used for user services...
  systemd.extraConfig = ''
    DefaultIPAccounting=true
  '';

  # NOTE: systemd-resolved actually breaks `hostname -f`!
  services.resolved = {
    enable = true;
    dnssec = "false"; # slow as fuck
  };

  services.tor = {
    enable = true;
    client = {
      enable = true;
      dns.enable = true;
    };

    settings = {
      HardwareAccel = 1;
      SafeLogging = 1;
    };
  };

  powerManagement.resumeCommands = ''
    ${config.systemd.package}/bin/systemctl try-restart tor.service
  '';
}

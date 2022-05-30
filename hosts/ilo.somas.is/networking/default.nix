{ config, ... }: {
  imports = [
    ./dns.nix
    ./tor.nix
    ./wifi.nix
  ];

  networking = {
    hostName = "ilo";
    domain = "somas.is";
    # search = [ "somas.is" ];

    hostId = builtins.substring 0 8 (builtins.hashString "sha256" "${config.networking.fqdn}");

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
  };

  # TODO: Track net usage by services
  #       Currently cannot by used for user services...
  systemd.extraConfig = ''
    DefaultIPAccounting=true
  '';
}

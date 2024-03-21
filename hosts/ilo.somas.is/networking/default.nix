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

  # services.udev.extraRules =
  #   let
  #     # NOTE: We use `iw` here instead because `crda` doesn't seem to work properly?
  #     update-reg = pkgs.writeShellScript "update-reg" ''
  #       PATH=${pkgs.geoclue2-with-demo-agent}/libexec/geoclue-2.0/demos:${lib.makeBinPath [ pkgs.curl pkgs.iw pkgs.jc pkgs.jq ]}:"$PATH"

  #       location=$(
  #           where-am-i \
  #               -a 1 \
  #               | jc --kv \
  #               | jq -r '
  #                   "latitude=\(.Latitude | rtrimstr("°") | @sh)",
  #                   "longitude=\(.Longitude | rtrimstr("°") | @sh)"
  #               '
  #       )
  #       eval "$location"

  #       COUNTRY=$(
  #           curl -Lf \
  #               --show-error \
  #               --no-progress-meter \
  #               --connect-timeout 60 \
  #               --retry 10 \
  #               --retry-delay 5 \
  #               --compressed \
  #               --get \
  #               -d format='json' \
  #               -d email='kylie+nixos@somas.is' \
  #               -d zoom='3' \
  #               -d lat="$latitude" \
  #               -d lon="$longitude" \
  #               'https://nominatim.openstreetmap.org/reverse' \
  #               | jq -r '.address.country_code | ascii_upcase'
  #       )

  #       exec iw reg set "$COUNTRY"
  #     '';
  #   in
  #   ''
  #     KERNEL=="regulatory*", ACTION=="change", SUBSYSTEM=="platform", RUN+="${update-reg}"
  #   '';

  # TODO: Track net usage by services
  #       Currently cannot by used for user services...
  systemd.extraConfig = ''
    DefaultIPAccounting=true
  '';

  # NOTE: systemd-resolved actually breaks `hostname -f`!
  services.resolved = {
    enable = true;
    dnssec = "false"; # slow as fuck and often broken
  };

  services.tor = {
    enable = false;
    client = {
      enable = true;
      dns.enable = true;
    };

    settings = {
      HardwareAccel = 1;
      SafeLogging = 1;

      ControlPort = 9051;
    };
  };

  powerManagement.resumeCommands = lib.mkIf config.services.tor.enable ''
    ${config.systemd.package}/bin/systemctl try-restart tor.service
  '';

  programs.kdeconnect.enable = true;
}

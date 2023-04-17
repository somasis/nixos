{ pkgs, ... }: {
  # NOTE: Disabled while trying to debug network stuff in my bedroom.
  # networking.wireless.iwd = {
  #   enable = true;
  #   settings = {
  #     General = {
  #       # Use the built in DHCP client.
  #       EnableNetworkConfiguration = true;

  #       # Randomize the MAC address based on the network being connected to.
  #       AddressRandomization = "network";
  #     };

  #     Network = {
  #       EnableIPv6 = false;
  #       # NameResolvingService = "resolvconf";
  #     };

  #     # Always prefer 5Ghz networks to 2.4Ghz ones when there's a choice.
  #     Rank.BandModifier5Ghz = 2.0;

  #     # Disable scanning for networks while connected.
  #     # This also means that whatever we end up connecting to, we will stay
  #     # connected to until the signal strength drops too low to go on.
  #     Scan.DisablePeriodicScan = true;
  #   };
  # };

  # HACK: Restart network stuff after resuming from sleep and at boot
  #       this really shouldn't be necessary.
  # powerManagement.powerUpCommands = "${config.systemd.package}/bin/systemctl try-restart resolvconf.service iwd.service";
  # powerManagement.resumeCommands = "${config.systemd.package}/bin/systemctl try-restart resolvconf.service iwd.service";

  networking.networkmanager = {
    enable = true;
    wifi.macAddress = "stable";

    # NOTE: Disabled while trying to debug network stuff in my bedroom.
    # dhcp = "dhcpcd";
    # dns = "dnsmasq";

    # TODO: fix this. "dnssec-trigger-script" doesn't exist, and so
    #       the unbound plugin is just hopelessly broken, it seems
    # dns = "unbound";
  };

  environment.persistence."/persist".directories = [
    "/etc/NetworkManager/system-connections"
    # "/var/lib/iwd"
  ];

  environment.persistence."/cache".directories = [
    "/var/lib/NetworkManager"
    # "/var/db/dhcpcd"
  ];
}

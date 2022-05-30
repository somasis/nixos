{ lib, ... }: {
  # This file was populated at runtime with the networking
  # details gathered from the active system.
  networking = {
    nameservers = [
      "8.8.8.8"
    ];

    defaultGateway = "68.183.0.1";
    defaultGateway6 = "2a03:b0c0:2:d0::1";

    dhcpcd.enable = false;

    usePredictableInterfaceNames = lib.mkForce false;

    interfaces = {
      eth0 = {
        ipv4.addresses = [
          { address = "68.183.0.67"; prefixLength = 20; }
          { address = "10.18.0.5"; prefixLength = 16; }
        ];
        ipv6.addresses = [
          { address = "2a03:b0c0:2:d0::f41:1"; prefixLength = 64; }
          { address = "fe80::a0e1:ceff:fe64:49c2"; prefixLength = 64; }
        ];
        ipv4.routes = [{ address = "68.183.0.1"; prefixLength = 32; }];
        ipv6.routes = [{ address = "2a03:b0c0:2:d0::1"; prefixLength = 128; }];
      };
    };
  };

  services.udev.extraRules = ''
    ATTR{address}=="a2:e1:ce:64:49:c2", NAME="eth0"
    ATTR{address}=="02:ff:24:0b:3d:e0", NAME="eth1"
  '';
}

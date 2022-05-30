{ config, ... }: {
  imports = [
    ./hardware-configuration.nix
    ./networking.nix # generated at runtime by nixos-infect
  ];

  lollypops.deployment = {
    host = "${config.networking.fqdn}";
    config-dir = "/etc/nixos";
  };

  boot.cleanTmpDir = true;
  zramSwap.enable = true;
  networking.hostName = "nixos";
  networking.domain = "somas.is";

  services.openssh.enable = true;
  users.users.root.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPkmjWLpicEaQOkM7FAv5bctmZjV5GjISYW7re0oknLU somasis@ilo.somas.is_20220603"
  ];
}

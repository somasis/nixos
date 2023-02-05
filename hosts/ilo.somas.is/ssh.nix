{ config, ... }: {
  services.openssh = {
    enable = true;
    forwardX11 = true;
    settings = {
      permitRootLogin = "no";
      passwordAuthentication = false;
    };

    hostKeys = [{ path = "/etc/ssh/host_ed25519"; type = "ed25519"; }];
  };

  programs.ssh = {
    knownHosts."spinoza.7596ff.com" = {
      extraHostNames = [ "spinoza" ];
      publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAroN0Hvz6bV+aRkm3aEWbP58QsNES5r6mhafHlraKnV";
    };

    extraConfig = ''
      Host spinoza.7596ff.com
        Port 1312
    '';
  };

  environment.persistence."/persist" = {
    files = [
      "/etc/ssh/host_ed25519"
      "/etc/ssh/host_ed25519.pub"
    ];

    users.root = {
      home = "/root";
      directories = [{ directory = ".ssh"; mode = "0700"; }];
    };
  };
}

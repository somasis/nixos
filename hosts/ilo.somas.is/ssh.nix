{ config, ... }: {
  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "no";
      PasswordAuthentication = false;
      X11Forwarding = true;
    };

    hostKeys = [{ path = "/etc/ssh/host_ed25519"; type = "ed25519"; }];
  };

  programs.ssh = {
    startAgent = true;

    knownHosts."spinoza.7596ff.com" = {
      extraHostNames = [ "spinoza" ];
      publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAroN0Hvz6bV+aRkm3aEWbP58QsNES5r6mhafHlraKnV";
    };
  };

  persist = {
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

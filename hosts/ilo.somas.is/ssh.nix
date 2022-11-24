{
  services.openssh = {
    enable = true;
    forwardX11 = true;
    passwordAuthentication = false;
    permitRootLogin = "no";

    hostKeys = [
      { path = "/etc/ssh/ssh_host_ed25519_key"; type = "ed25519"; }
    ];
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

  environment.persistence."/persist".files = [
    "/etc/ssh/ssh_host_ed25519_key"
    "/etc/ssh/ssh_host_ed25519_key.pub"
  ];
}

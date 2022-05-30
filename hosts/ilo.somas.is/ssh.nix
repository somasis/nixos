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

  # This is only necessary because of using these machines as substituters
  programs.ssh = {
    knownHosts = {
      "spinoza.7596ff.com" = {
        extraHostNames = [ "spinoza" ];
        publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAroN0Hvz6bV+aRkm3aEWbP58QsNES5r6mhafHlraKnV";
      };

      "trotsky.somas.is" = {
        extraHostNames = [ "trotsky" ];
        publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPpordJdpvdP1FwfxTmJoWdy0xQ9bPPLRGllA0uHOle0";
      };
    };

    extraConfig = ''
      Host spinoza.7596ff.com
        Port 1312
      Host trotsky.somas.is
        Port 5398
    '';
  };

  environment.persistence."/persist".files = [
    "/etc/ssh/ssh_host_ed25519_key"
    "/etc/ssh/ssh_host_ed25519_key.pub"
  ];
}

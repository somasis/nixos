{ pkgs, ... }: {
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
    ${pkgs.systemd}/bin/systemctl restart tor.service
  '';
}

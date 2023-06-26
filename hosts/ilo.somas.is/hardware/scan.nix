{ pkgs, ... }: {
  hardware.sane = {
    enable = true;
    openFirewall = true;
  };

  environment.systemPackages = [ pkgs.simple-scan ];
}

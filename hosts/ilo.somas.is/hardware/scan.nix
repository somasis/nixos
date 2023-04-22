{ pkgs, ... }: {
  hardware.sane = {
    enable = true;
    openFirewall = true;
    brscan5.enable = true;
  };

  environment.systemPackages = [ pkgs.simple-scan ];
}

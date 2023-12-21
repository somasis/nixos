{ pkgs, ... }: {
  hardware.sane = {
    enable = true;
    openFirewall = true;

    extraBackends = [
      pkgs.hplipWithPlugin
      pkgs.sane-airscan
    ];
  };

  environment.systemPackages = [ pkgs.simple-scan ];
}

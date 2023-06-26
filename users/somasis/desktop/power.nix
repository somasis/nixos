{ pkgs
, osConfig
, ...
}: {
  services.batsignal = {
    enable = true;

    extraArgs = [ "-e" ]
      ++ [ "-I" "battery" ]
      ++ [ "-D" "${pkgs.systemd}/bin/systemctl suspend" ]
      ++ [ "-w" (builtins.toString osConfig.services.upower.percentageLow) ]
      ++ [ "-c" (builtins.toString osConfig.services.upower.percentageCritical) ]
    ;
  };
}

{ config
, pkgs
, ...
}: {
  boot.kernelModules = [ "ddcci" ];
  boot.extraModulePackages = with config.boot.kernelPackages; [ ddcci-driver ];

  # services.udev.extraRules = ''
  #   # ACTION=="change", SUBSYSTEM=="drm_*", RUN+="${pkgs.bash}/bin/sh -c '${pkgs.kmod}/bin/modprobe -r ddcci_backlight && ${pkgs.kmod}/bin/modprobe ddcci_backlight'"
  #   # ACTION=="change", SUBSYSTEM=="i2c", RUN+="${pkgs.bash}/bin/sh -c '${pkgs.kmod}/bin/modprobe -r ddcci_backlight && ${pkgs.kmod}/bin/modprobe ddcci_backlight'"
  # '';
}

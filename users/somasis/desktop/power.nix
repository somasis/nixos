{ pkgs
, osConfig
, ...
}: {
  home.packages = [ pkgs.batsignal ];

  systemd.user.services.batsignal = {
    Unit = {
      Description = pkgs.batsignal.meta.description;
      PartOf = [ "graphical-session.target" ];
    };
    Install.WantedBy = [ "graphical-session.target" ];

    Service = {
      Type = "simple";
      ExecStart = ''
        ${pkgs.batsignal}/bin/batsignal \
          -e \
          -I "battery" \
          -D "${pkgs.systemd}/bin/systemctl suspend" \
          -w "${builtins.toString osConfig.services.upower.percentageLow}" \
          -c "${builtins.toString osConfig.services.upower.percentageCritical}"
      '';

      Restart = "on-failure";
      RestartSec = 1;
    };
  };
}

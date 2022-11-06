{ pkgs
, nixosConfig
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
          -w "${builtins.toString nixosConfig.services.upower.percentageLow}" \
          -c "${builtins.toString nixosConfig.services.upower.percentageCritical}"
      '';

      Restart = "on-failure";
      RestartSec = 1;
    };
  };
}

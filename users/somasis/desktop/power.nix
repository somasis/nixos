{ pkgs, ... }: {
  home.packages = [ pkgs.batsignal ];

  systemd.user.services.batsignal = {
    Service.Type = "simple";
    Service.ExecStart = ''
      ${pkgs.batsignal}/bin/batsignal \
        -I 'battery' \
        -e \
        -D '${pkgs.systemd}/bin/systemctl suspend'
    '';
    Service.Restart = "on-failure";
    Service.RestartSec = 1;
    Install.WantedBy = [ "graphical-session.target" ];
    Unit.PartOf = [ "graphical-session.target" ];
  };
}

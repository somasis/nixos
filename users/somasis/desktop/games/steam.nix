{ config, pkgs, ... }: {
  xsession.windowManager.bspwm.rules."Steam".border = false;

  home.persistence."/persist${config.home.homeDirectory}" = {
    directories = [ "share/Steam" ];
  };

  systemd.user.services.steam = {
    Unit.Description = "Keep Steam client running in the background";
    Install.WantedBy = [ "graphical-session.target" ];
    Unit.PartOf = [ "graphical-session.target" ];
    Service.Type = "simple";
    Service.ExecStart = "${pkgs.steam}/bin/steam -silent";
    Service.Restart = "on-failure";
  };
}

{ config
, nixosConfig
, ...
}:
assert nixosConfig.programs.steam.enable;
{
  home.persistence."/persist${config.home.homeDirectory}" = {
    directories = [ "share/Steam" ];
  };

  systemd.user.services.steam = {
    Unit = {
      Description = "Keep Steam client running in the background";
      PartOf = [ "graphical-session.target" ];
    };

    Install.WantedBy = [ "graphical-session.target" ];
    Service = {
      Type = "simple";
      ExecStart = "${nixosConfig.programs.steam.package}/bin/steam -silent";
      Restart = "on-failure";
    };
  };

  # Keep Steam easy-going in the background.
  services.xsuspender.rules.Steam = {
    matchWmClassContains = "Steam";
    downclockOnBattery = 1;
    suspendDelay = 15;
    resumeEvery = 60;
    resumeFor = 5;
  };

  xsession.windowManager.bspwm.rules."Steam".border = false;
}

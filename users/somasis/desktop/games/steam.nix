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
      ExecStart = "${nixosConfig.programs.steam.package}/bin/steam -silent -no-browser";
      Restart = "on-failure";

      Nice = 19;
      CPUSchedulingPolicy = "idle";
      IOSchedulingClass = "idle";
      IOSchedulingPriority = 7;
    };
  };

  # Keep Steam easy-going in the background.
  services.xsuspender.rules.steam = {
    matchWmClassContains = "Steam";
    downclockOnBattery = 1;
    suspendDelay = 15;
    resumeEvery = 60;
    resumeFor = 5;
  };

  xsession.windowManager.bspwm.rules."Steam".border = false;
}

{ config
, lib
, osConfig
, ...
}:
let inherit (osConfig.programs) steam; in
lib.mkIf steam.enable {
  persist.directories = [ "share/Steam" ];

  systemd.user.services.steam = {
    Unit = {
      Description = steam.package.meta.description;
      PartOf = [ "graphical-session.target" ];
    };

    Install.WantedBy = [ "graphical-session.target" ];
    Service = {
      Type = "simple";
      ExecStart = "${steam.package}/bin/steam -silent -no-browser";
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

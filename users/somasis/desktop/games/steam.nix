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

      Environment = [ "STEAM_FORCE_DESKTOPUI_SCALING=1.5" ];
      ExecStart = "${steam.package}/bin/steam -silent";

      # We need to kill the PID listed in ~/.steampid, or else Steam
      # will exit unsuccesfully every time.
      PIDFile = "%h/.steampid";

      Restart = "on-failure";

      # Keep Steam easy-going in the background.
      Nice = 19;
      CPUSchedulingPolicy = "idle";
      IOSchedulingClass = "idle";
      IOSchedulingPriority = 7;
    };
  };
}

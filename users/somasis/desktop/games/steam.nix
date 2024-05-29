{ config
, pkgs
, lib
, osConfig
, ...
}:
let inherit (osConfig.programs) steam; in
assert steam.enable;
{
  persist.directories = [
    ".steam"
    (config.lib.somasis.xdgDataDir "Steam")

    { method = "symlink"; directory = "etc/r2modman"; }
    { method = "symlink"; directory = "etc/r2modmanPlus-local"; }
  ];

  home.packages = [ pkgs.r2modman ];

  # systemd.user.services.steam = {
  #   Unit.Description = steam.package.meta.description;
  #   Unit.PartOf = [ "graphical-session-autostart.target" ];
  #   Install.WantedBy = [ "graphical-session-autostart.target" ];

  #   Service = {
  #     Type = "simple";

  #     Environment = [ "STEAM_FORCE_DESKTOPUI_SCALING=1.5" ];
  #     ExecStart = "${steam.package}/bin/steam -silent -single_core";
  #     ExecStop = "${steam.package}/bin/steam -shutdown";

  #     # We need to kill the PID listed in ~/.steampid, or else Steam
  #     # will exit unsuccesfully every time.
  #     PIDFile = "%h/.steampid";

  #     Restart = "on-failure";

  #     # Keep Steam easy-going in the background.
  #     Nice = 19;
  #     CPUSchedulingPolicy = "idle";
  #     IOSchedulingClass = "idle";
  #     IOSchedulingPriority = 7;
  #   };
  # };

  # services.xsuspender.rules.steam = {
  #   matchWmClassGroupContains = "steam";
  #   downclockOnBattery = 0;
  #   suspendDelay = 15;
  #   resumeEvery = 180;
  #   resumeFor = 5;
  # };
}

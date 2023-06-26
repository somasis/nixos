{ osConfig
, config
, lib
, pkgs
, ...
}: {
  imports = [
    ./calendars.nix
    ./contacts.nix
  ];

  cache.directories = [{ method = "symlink"; directory = "share/vdirsyncer"; }];

  programs.vdirsyncer.enable = true;
  services.vdirsyncer = {
    enable = true;
    verbosity = "WARNING";
    frequency = "*:0";
  };

  systemd.user = {
    services.vdirsyncer.Service = {
      ExecCondition =
        lib.optional osConfig.networking.networkmanager.enable
          "${pkgs.networkmanager}/bin/nm-online -q";

      Nice = 19;
      CPUSchedulingPolicy = "idle";
      IOSchedulingClass = "idle";
      IOSchedulingPriority = 7;
    };

    timers.vdirsyncer.Timer.OnStartupSec = 900;

    paths.vdirsyncer = {
      Unit.Description = "Synchronize calendars and contacts on local changes";
      Install.WantedBy = [ "default.target" ];

      Path.PathChanged = [
        config.accounts.contact.basePath
        config.accounts.calendar.basePath
      ];
    };
  };
}

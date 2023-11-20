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
      ExecCondition = pkgs.writeShellScript "if-vdirsyncer-not-running" ''
        vdirsyncer_procs=$(${pkgs.procps}/bin/pgrep -c -u "$USER" vdirsyncer 2>/dev/null)
        test "''${vdirsyncer_procs:-0}" -eq 0
      '';

      ExecStartPre = lib.mkIf osConfig.networking.networkmanager.enable "${pkgs.networkmanager}/bin/nm-online -q";

      Nice = 19;
      CPUSchedulingPolicy = "idle";
      IOSchedulingClass = "idle";
      IOSchedulingPriority = 7;
    };

    timers.vdirsyncer.Timer.OnStartupSec = 900;

    paths.vdirsyncer = {
      Unit.Description = "Synchronize calendars and contacts on local changes";
      Install.WantedBy = [ "paths.target" ];

      Path.PathModified =
        [ config.accounts.contact.basePath config.accounts.calendar.basePath ]
        ++ lib.optionals ((builtins.attrNames config.accounts.contact.accounts) != [ ])
          (lib.mapAttrsToList (_: account: account.local.path) config.accounts.contact.accounts)
        ++ lib.optionals ((builtins.attrNames config.accounts.calendar.accounts) != [ ])
          (lib.mapAttrsToList (_: account: account.local.path) config.accounts.calendar.accounts)
      ;
    };
  };
}

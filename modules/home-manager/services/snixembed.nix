{ pkgs
, lib
, config
, ...
}:
let
  cfg = config.services.snixembed;
  pkg = config.services.snixembed.package;

  inherit (lib)
    types
    getExe
    mkIf
    ;

  inherit (lib.cli)
    toGNUCommandLineShell
    ;

  inherit (lib.options)
    mkEnableOption
    mkPackageOption
    ;
in
{
  options.services.snixembed = {
    enable = mkEnableOption "a daemon that turns Status Notifier Icons into standard XEmbed system tray icons";
    package = mkPackageOption pkgs "snixembed" { };
  };

  config.systemd.user.services.snixembed = mkIf cfg.enable {
    Unit = {
      Description = pkg.meta.description;
      PartOf = [ "tray.target" ];
    };
    Install.WantedBy = [ "tray.target" ];

    Service = {
      Type = "dbus";
      BusName = "org.kde.StatusNotifierWatcher";
      ExecStart = getExe pkg;
    };
  };
}

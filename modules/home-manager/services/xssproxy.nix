{ lib
, config
, pkgs
, ...
}:
let
  cfg = config.services.xssproxy;
  pkg = config.services.xssproxy.package;

  inherit (lib)
    types

    getExe
    concatStringsSep
    ;

  inherit (lib.cli)
    toGNUCommandLineShell
    ;

  inherit (lib.options)
    mkOption
    mkEnableOption
    mkPackageOption
    ;
in
{
  options.services.xssproxy = {
    enable = mkEnableOption "a service for forwarding requests for screensaver inhibition to Xorg's XScreenSaver API";
    package = mkPackageOption pkgs "xssproxy" { };

    verbose = mkEnableOption "showing inhibition events in the user journal";

    ignore = mkOption {
      type = with types; listOf nonEmptyStr;
      default = [ ];
      description = ''
        Ignore inhibition requests from applications named in this list.

        If you run `xssproxy --verbose` manually, you can see the names of
        applications requesting inhibition.
      '';
    };
  };

  config = {
    systemd.user.services.xssproxy = {
      Unit = {
        Description = pkg.meta.description;
        PartOf = [ "graphical-session.target" ];
      };
      Install.WantedBy = [ "graphical-session.target" ];

      Service = {
        Type = "dbus";
        BusName = "org.freedesktop.ScreenSaver";
        ExecStart = concatStringsSep " " [
          (getExe pkg)
          (toGNUCommandLineShell { } { inherit (cfg) verbose ignore; })
        ];
      };
    };
  };
}

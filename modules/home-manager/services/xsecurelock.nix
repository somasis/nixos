{ lib
, config
, pkgs
, ...
}:
let
  cfg = config.services.xsecurelock;
  pkg = config.services.xsecurelock.package;

  inherit (lib)
    types

    getExe
    replaceStrings
    literalExpression
    escape
    mapAttrsToList
    mergeAttrs
    mkIf
    optionalString
    ;

  inherit (lib.generators)
    mkValueStringDefault
    ;

  inherit (lib.options)
    mkOption
    mkEnableOption
    mkPackageOption
    ;

  # escapeSystemd = x: escape [ "\"" ] (replaceStrings [ "%" ] [ "%%" ] (toString x));
  escapeSystemd = x: escape [ "\"" ] (replaceStrings [ "%" ] [ "%%" ] (toString x));
in
{
  options.services.xsecurelock = {
    enable = mkEnableOption "a screen-locker designed with an emphasis on security";
    package = mkPackageOption pkgs "xsecurelock" { };

    harden = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Harden the `xsecurelock` run environment more.

        This will...
        - Set `ProtectHome=read-only`, and `ProtectSystem=strict` (see systemd.exec(5)).
        - Clear the runtime environment of all environment variables, and pass only
          $DISPLAY, $HOME, $USER, $XAUTHORITY, and any environment variables that
          will be set by `services.xsecurelock.settings`, and
          `services.xsecurelock.keyBindings`.
      '';
    };

    successCommand = mkOption {
      type = with types; nullOr (coercedTo (oneOf [ nonEmptyStr path ]) toString str);
      default = null;
      example = literalExpression "\${pkgs.systemd}/systemctl --user start idle.target";
      description = ''
        A command that `xsecurelock` should execute once it locks the screen
        successfully. Note that `xsecurelock` must be able to execute the
        command from within its runtime environment, so consider if the
        value of `services.xsecurelock.harden` might affect it.
      '';
    };

    settings = mkOption rec {
      type = with types; attrsOf (coercedTo (nullOr (oneOf [ str number path ])) (mkValueStringDefault { }) str);
      apply = mergeAttrs default;

      default = {
        XSECURELOCK_XSCREENSAVER_PATH = config.services.xscreensaver.package;
        XSECURELOCK_WAIT_TIME_MS = (config.services.screen-locker.inactiveInterval * 60) * 1000;
      };

      defaultText = literalExpression ''
        {
          XSECURELOCK_XSCREENSAVER_PATH = config.services.xscreensaver.package;
          XSECURELOCK_WAIT_TIME_MS = (config.services.screen-locker.inactiveInterval * 60) * 1000;
        }
      '';
      description = ''
        Environment variables that should be set in `xsecurelock`'s environment.

        See <https://github.com/google/xsecurelock/tree/${pkg.src.rev}#options>
        for a list of environment variables that `xsecurelock` uses.
      '';
    };

    keyBindings = mkOption rec {
      type = with types; attrsOf (coercedTo (nullOr (oneOf [ str path ])) (mkValueStringDefault { }) str);
      apply = mergeAttrs default;
      default = { };
      example = {
        p = literalExpression "\${pkgs.playerctl}/bin/playerctl play-pause";
      };

      description = ''
        An attribute set of X11 keysyms (consult `xev` to find out a key's keysym
        name). When `xsecurelock` is active, if the key in question is pressed,
        it will run its corresponding command.
      '';
    };
  };

  config = mkIf cfg.enable {
    systemd.user.services.xsecurelock = {
      Unit.Description = pkg.meta.description;

      # services.systemd-lock-handler integration
      Unit.PartOf = [ "lock.target" ];
      Unit.After = [ "lock.target" ];
      Unit.OnSuccess = [ "unlock.target" ];
      Install.WantedBy = [ "lock.target" ];

      Service = {
        # Type = "notify";
        # NotifyAccess = "all";
        # ExecStart = "${getExe xsecurelockPkg} -- systemd-notify --ready --status='Locked successfully'";
        # PassEnvironment = [ "NOTIFY_SOCKET" ];

        ProtectHome = mkIf cfg.harden "read-only";
        ProtectSystem = mkIf cfg.harden "strict";
        PassEnvironment = mkIf cfg.harden (
          [ "DISPLAY" "XAUTHORITY" "HOME" "USER" ]
          ++ builtins.attrNames cfg.settings
          ++ builtins.attrNames cfg.keyBindings
        );

        Type =
          if cfg.successCommand == null then
            "forking"
          else
            "exec"
        ;

        Environment =
          mapAttrsToList (n: v: ''"${n}=${escapeSystemd v}"'') cfg.settings
          ++ mapAttrsToList (key: command: ''"XSECURELOCK_KEY_${key}=${escapeSystemd command}"'') cfg.keyBindings
        ;

        ExecStart = getExe pkg + optionalString (cfg.successCommand != null) "-- ${cfg.successCommand}";

        Restart = "on-failure";
        RestartSec = 0;
      };
    };
  };
}

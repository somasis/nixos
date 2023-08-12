{ config
, lib
, pkgs
, ...
}:
with builtins;
with lib;
let
  inherit (config.lib.somasis)
    camelCaseToScreamingSnakeCase
    getExe
    ;

  inherit (config.xsession.windowManager) bspwm;

  cfg = config.services.panel;
  pkg = cfg.package;

  xres = config.xresources.properties;

  toEnvVarName = string:
    pipe string [
      camelCaseToScreamingSnakeCase
      toUpper
    ]
  ;

  mkColorOption = name: default: config.lib.somasis.mkColorOption {
    inherit default;
    description = ''
      Color to be used by panel for ${name}.
      Accessible from modules via $PANEL_COLOR_${toEnvVarName name}.
    '';
    format = "hex";
  };

  mkModulesOption = name: mkOption {
    type = with types; dagOf (submodule (
      { config, ... }: {
        options = {
          enable = mkOption {
            type = types.bool;
            description = "Whether to activate the module or not.";
            default = true;
            example = false;
          };

          name = mkOption {
            type = types.nonEmptyStr;
            default = "";
            description = ''
              Name of the module, used to name the variable corresponding to the module's output,
              and for ordering the modules in the different alignment sets.
            '';
          };

          command = mkOption {
            type = with types; oneOf [ nonEmptyStr path ];
            description = "Command to run, whose output will be shown on the panel.";
            default = null;
            example = "fortune";
          };

          align = mkOption {
            type = types.enum [ "left" "center" "right" ];
            description = "Which column of the panel to place the module in.";
            default = "left";
            example = "right";
          };

          monitor = mkOption {
            type = with types; either (enum [ "all" "primary" ]) nonEmptyStr;
            description = "Monitor on which the panel should show the module.";
            default = "primary";
            example = "eDP-1";
          };
        };
      }
    ));

    description = ''
      Modules in the ${name} column.
      The order in which modules should be displayed is controlled using
      Home Manager's DAG functions.
    '';

    default = { };
  };
in
{
  options.services.panel = {
    enable = mkEnableOption "a lemonbar-based panel";

    debug = mkOption {
      type = types.bool;
      description = "Enable debug output.";
      default = false;
      example = true;
    };

    lemonbarPackage = mkOption {
      type = types.package;
      description = ''
        The package to use for lemonbar.
        It must provide a /bin/lemonbar binary.
      '';

      default = pkgs.lemonbar-xft;
      defaultText = literalExpression "pkgs.lemonbar-xft";

      # apply = prevPackage: prevPackage.overrideAttrs (finalAttrs: previousAttrs: {
      #   CPPFLAGS = (previousAttrs.CPPFLAGS or "")
      #     + " -D MAX_FONT_COUNT=${toString (length (attrNames cfg.fonts))}";
      # });
    };

    package = mkOption {
      type = types.package;
      description = "The package that provides /bin/panel.";
      readOnly = true;

      defaultText = literalExpression "panel overriden with configuration options";
    };

    interpreter = mkOption {
      type = with types; oneOf [ nonEmptyStr path ];
      description = "The command that will process lemonbar's output.";

      default = pkgs.runtimeShell;
      example = literalExpression "\${pkgs.bash}/bin/bash -x -";
    };

    extraArgs = mkOption {
      type = with types; str;
      description = "Extra arguments to pass to lemonbar.";
      default = "";
      example = "-d";
    };

    clickableAreas = mkOption {
      type = types.ints.positive;
      description = "Set number of clickable areas on the panel.";
      default = 64;
    };

    dock = mkOption {
      type = types.enum [ "top" "bottom" ];
      description = "Dock the bar at the top or bottom of the screen.";
      default = "top";
      example = "bottom";
    };

    colors = {
      background = mkColorOption "background" "#000000";
      foreground = mkColorOption "foreground" "#ffffff";
      accent = mkColorOption "accent" "#0000ff";
      black = mkColorOption "black" "#000000";
      red = mkColorOption "red" "#ff0000";
      green = mkColorOption "green" "#00ff00";
      yellow = mkColorOption "yellow" "#ffff00";
      blue = mkColorOption "blue" "#0000ff";
      magenta = mkColorOption "magenta" "#ff00ff";
      cyan = mkColorOption "cyan" "#00ffff";
      white = mkColorOption "white" "#d3d3d3";
      brightBlack = mkColorOption "bright black" "#808080";
      brightRed = mkColorOption "bright red" "#ffa500";
      brightGreen = mkColorOption "bright green" "#00ff00";
      brightYellow = mkColorOption "bright yellow" "#f0e68c";
      brightBlue = mkColorOption "bright blue" "#4169e1";
      brightMagenta = mkColorOption "bright magenta" "#ee82ee";
      brightCyan = mkColorOption "bright cyan" "#00ffff";
      brightWhite = mkColorOption "bright white" "#fffafa";

      underline = mkColorOption "underline" cfg.colors.foreground;
    };

    fonts = mkOption {
      type = with types; attrsOf nonEmptyStr;

      description = ''
        Fonts to use for panel text.
        The attribute names correspond to $PANEL_FONT_<name>.

        An attribute named "default" is required.
      '';

      default = {
        default = "monospace";
      };
    };

    geometry = {
      width = mkOption {
        type = with types; nullOr ints.positive;
        description = ''
          Width of the panel.
          If null, use the full width of the primary monitor.
        '';
        default = null;
      };

      height = mkOption {
        type = with types; nullOr ints.positive;
        description = ''
          Height of the panel.
          If null, use the height of the default font.
        '';
        default = null;
      };

      x = mkOption {
        type = with types; nullOr ints.positive;
        description = "X position of the panel.";
        default = null;
      };

      y = mkOption {
        type = with types; nullOr ints.positive;
        description = "Y position of the panel.";
        default = null;
      };
    };

    textOffset = mkOption {
      type = types.ints.positive;
      description = "How many pixels to offset text from the top of the panel.";
      default = 10;
    };

    overlineHeight = mkOption {
      type = types.ints.positive;
      description = "Set the height of the overline.";
      default = 1;
    };

    underlineHeight = mkOption {
      type = types.ints.positive;
      description = "Set the height of the underline.";
      default = 1;
    };

    modules = {
      left = mkModulesOption "left";
      center = mkModulesOption "center";
      right = mkModulesOption "right";
    };
  };

  config = mkIf cfg.enable {
    assertions = [{
      assertion = elem "default" (attrNames cfg.fonts);
      message = ''
        `services.panel.fonts` has no `default` font set.
      '';
    }];

    services.panel.package = pkgs.callPackage ./panel.nix {
      inherit toEnvVarName;

      inherit (cfg)
        debug
        colors
        fonts
        interpreter
        lemonbarPackage
        modules
        ;

      lemonbarExtraArgs = lib.concatStringsSep " " [
        (lib.cli.toGNUCommandLineShell { } {
          g = with cfg.geometry; "${toString width}x${toString height}+${toString x}+${toString y}";

          b = cfg.dock == "bottom";

          f = attrValues cfg.fonts;

          B = cfg.colors.background;
          F = cfg.colors.foreground;
          U = cfg.colors.underline;

          o = cfg.textOffset;

          u = cfg.underlineHeight;
          l = cfg.overlineHeight;

          a = cfg.clickableAreas;
        })

        cfg.extraArgs
      ];
    };

    home.packages = [ cfg.package ];

    # systemd.user.services.panel = {
    #   Unit = {
    #     Description = "lemonbar(1) based panel";
    #     PartOf = [ "tray.target" "graphical-session-post.target" ];
    #   };
    #   Install.WantedBy = [ "tray.target" "graphical-session-post.target" ];

    #   Service = {
    #     Type = "notify";

    #     ExecStart = [ "${cfg.package}/bin/panel" ];

    #     ExecStartPost = [
    #       "${bspwm.package}/bin/bspc config top_padding ${toString bspwm.settings.top_padding}"
    #       "${bspwm.package}/bin/bspc config border_width ${toString bspwm.settings.border_width}"
    #       "${bspwm.package}/bin/bspc config window_gap ${toString bspwm.settings.window_gap}"
    #     ];

    #     ExecStopPost = [
    #       "${bspwm.package}/bin/bspc config top_padding 0"
    #       "${bspwm.package}/bin/bspc config border_width 0"
    #       "${bspwm.package}/bin/bspc config window_gap 0"
    #     ];

    #     Restart = "on-success";
    #   };

    #   Unit.StartLimitInterval = 0;
    # };

    programs.autorandr.hooks = {
      preswitch.panel = "${pkgs.systemd}/bin/systemctl --user stop panel.service";
      postswitch.panel = "${pkgs.systemd}/bin/systemctl --user start panel.service";
    };
  };
}

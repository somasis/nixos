{ config
, lib
, pkgs
, ...
}:
with lib;
let
  cfg = config.services.stw;
  pkg = cfg.package;
  stw = "${pkg}/bin/stw";

  # We have to special case the -0 since Nix will change it to 0.
  intOrPercentType = types.oneOf [ (types.strMatching "^-?(100|[0-9][0-9]?)%$|^-0$") types.int ];
  colorType = types.strMatching "^#([0-9a-f]{3}|[0-9a-f]{6})$|^([a-zA-Z ]+)$";

  mkScript = widget:
    let
      args = with widget; lib.cli.toGNUCommandLineShell { } {
        t = window.top;
        x = window.position.x;
        y = window.position.y;
        X = window.position.xRelative;
        Y = window.position.yRelative;
        a = builtins.substring 0 1 text.align;
        f = text.color;
        b = window.color;
        F = text.font;
        B = window.padding;
        p = update;
        A = window.opacity;
      };
    in
    pkgs.writeShellScriptBin "stw-widget-${widget.name}" ''
      ${lib.optionalString (widget.update == 0) "[[ -v NOTIFY_SOCKET ]] && ${pkgs.systemd}/bin/systemd-notify --ready"}
      exec ${stw} ${args} -- ${pkgs.writeShellScript "stw-widget-${widget.name}-command" widget.command}
    '';
in
{
  options.services.stw = {
    enable = mkEnableOption "text widgets on the root window";

    package = mkOption {
      type = types.package;
      default = pkgs.stw;
      description = "Package to use for stw.";
    };

    widgets = mkOption {
      type = types.attrsOf (types.submodule (
        { name, config, ... }: {
          options = {
            enable = mkOption {
              type = types.bool;
              description = "Whether to start the widget at login or not.";
              default = true;
              example = false;
            };

            name = mkOption {
              type = types.str;
              default = name;
              readOnly = true;
              description = ''
                Name used by `stw-widget-<name>` and stw@<name>.service
              '';
            };

            command = mkOption {
              type = with types; oneOf [ nonEmptyStr path ];
              description = "Command to run, whose output will be the widget text.";
              default = null;
              example = "fortune";
            };

            update = mkOption {
              type = with types; addCheck int (x: x >= -1);
              description = ''
                How often to run the command.

                Valid values are 0 (only run once; reload service or send SIGALRM to update), -1 (run again after command exits),
                or an amount of seconds as an integer >0.
              '';
              default = 5;
              example = -1;
            };

            text = {
              align = mkOption {
                # stw(1) just takes "l", "c", and "r" for -a arguments
                type = with types; nullOr (enum [ "left" "center" "right" ]);
                description = "Alignment of widget text (left, center, right).";
                default = "left";
                example = "right";
              };

              color = mkOption {
                type = with types; nullOr colorType;
                description = ''Color of widget text, as a hex color code (#f0f0f0) or an Xorg color name ("alice blue").'';
                default = null;
                example = "alice blue";
              };

              font = mkOption {
                type = with types; nullOr str;
                description = "Font of widget text.";
                default = null;
                example = "monospace:size=20";
              };
            };

            window = {
              color = mkOption {
                type = with types; nullOr colorType;
                description = ''Color of widget background, as a hex color code (#f0f0f0) or an Xorg color name ("blue").'';
                default = null;
                example = "#f0f0f0";
              };

              opacity = mkOption {
                type = with types; nullOr (numbers.between 0.0 1.0);
                description = "Widget background opacity.";
                default = null;
                example = 0.75;
              };

              padding = mkOption {
                type = with types; nullOr int;
                description = "Gap between widget border or text.";
                default = null;
                example = 4;
              };

              position = {
                x = mkOption {
                  type = with types; nullOr intOrPercentType;
                  description = ''
                    X position of widget on screen.

                    Due to how Nix handles negative zero, if you want to set this to -0 you must write it as a string.
                  '';
                  default = 0;
                  example = "50%";
                };

                y = mkOption {
                  type = with types; nullOr intOrPercentType;
                  description = ''
                    Y position of widget on screen.

                    Due to how Nix handles negative zero, if you want to set this
                    to -0, you must write it as a string.
                  '';
                  default = 0;
                  example = "50%";
                };

                xRelative = mkOption {
                  type = with types; nullOr intOrPercentType;
                  description = ''
                    X position relative to widget width and height.

                    Due to how Nix handles negative zero, if you want to set this
                    to -0, you must write it as a string.
                  '';
                  default = null;
                  example = "-50%";
                };

                yRelative = mkOption {
                  type = with types; nullOr intOrPercentType;
                  description = ''
                    Y position relative to widget width and height.

                    Due to how Nix handles negative zero, if you want to set this
                    to -0, you must write it as a string.
                  '';
                  default = 0;
                  example = "-50%";
                };
              };

              top = mkOption {
                type = types.bool;
                description = "Place widget on top of other windows";
                default = false;
                example = true;
              };
            };
          };
        }
      ));

      description = "List of widgets to create.";

      default = { };

      example = {
        dates = {
          command = ''
            ${literalExpression "${pkgs.coreutils}"}/bin/date +"%Y-%m-%d %I:%M %p"
          '';

          text = {
            color = "#ffffff";
            font = "monospace:style=heavy:size=10";
          };

          window = {
            color = "#000000";
            opacity = 0.5;
            padding = 12;
            position.x = -24;
            position.y = 72;
            top = true;
          };

          update = 60;
        };
      };
    };
  };

  config = mkIf cfg.enable {
    systemd.user = foldr
      (
        widget:
        units:
        lib.recursiveUpdate units {
          targets."stw" = {
            Unit = {
              Description = "All text widgets on the root window";
              PartOf = [ "graphical-session-post.target" ];
            };
            Install.WantedBy = [ "graphical-session-post.target" ];
          };

          services."stw@${widget.name}" = {
            Unit.Description = "${pkg.meta.description}, instance '${widget.name}'";
            Unit.PartOf = lib.optional widget.enable "stw.target";
            Install.WantedBy = lib.optional widget.enable "stw.target";

            Service = {
              Type =
                if widget.update == null then
                  "notify"
                else
                  "simple";

              ExecStart = [ "${mkScript widget}/bin/stw-widget-${widget.name}" ];
              ExecReload = "${pkgs.procps}/bin/kill -ALRM $MAINPID";
            };
          };
        }
      )
      {
        targets.stw = {
          Unit = {
            Description = "All text widgets on the root window";
            PartOf = [ "graphical-session-post.target" "default.target" ];
          };

          Install.WantedBy = [ "graphical-session-post.target" "default.target" ];
        };
      }
      (lib.mapAttrsToList (n: v: v) cfg.widgets)
    ;

    home.packages = [ pkg ]
      ++ (lib.mapAttrsToList (n: v: mkScript v) cfg.widgets)
    ;
  };
}

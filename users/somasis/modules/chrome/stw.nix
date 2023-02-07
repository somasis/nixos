{ config
, lib
, pkgs
, ...
}:
with lib;
let
  cfg = config.somasis.chrome.stw;
  pkg = cfg.package;
  stw = "${pkg}/bin/stw";

  intOrPercentType = types.either types.int (types.strMatching "^-?[0-9]{2,3}%$");
  colorType = types.strMatching "^#([0-9a-f]{3}|([0-9a-f]{6}|[a-zA-Z ]+)$)";
in
{
  options.somasis.chrome.stw = {
    enable = mkEnableOption "Enable text widgets on the root window";

    package = mkOption {
      type = types.package;
      default = pkgs.stw;
      description = "Package to use for stw.";
    };

    widgets = mkOption {
      type = types.listOf (types.submodule (
        { config, ... }: {
          options = {
            command = mkOption {
              type = types.str;
              description = "Command to run, whose output will be the widget text";
              default = null;
              example = "fortune";
            };

            name = mkOption {
              type = types.str;
              description = "Pretty name for use by other stuff";
              default = (builtins.head (builtins.split " " (builtins.baseNameOf (builtins.toString config.command))));
              example = "fortune";
            };

            update = mkOption {
              type = with types; nullOr (either (enum [ "none" "instant" ]) (ints.positive));
              description = ''
                How often to run the command.

                Valid values "none" (only run once), "instant" (run again when command exits),
                or an integer >0.
              '';
              default = 5;
              example = "instant";
            };

            text = {
              align = mkOption {
                # stw(1) just takes "l", "c", and "r" for -a arguments
                type = with types; nullOr (enum [ "left" "center" "right" ]);
                description = "Alignment of widget text (left, center, right)";
                default = null;
                example = "left";
              };

              color = mkOption {
                type = with types; nullOr colorType;
                description = "Color of widget text, as a hex color code (#f0f0f0) or an Xorg color name (alice blue)";
                default = null;
                example = "alice blue";
              };

              font = mkOption {
                type = with types; nullOr str;
                description = "Font of widget text";
                default = null;
                example = "monospace:size=20";
              };
            };

            window = {
              color = mkOption {
                type = with types; nullOr colorType;
                description = "Color of widget background, as a hex color code (#f0f0f0) or an Xorg color name (blue)";
                default = null;
                example = "#f0f0f0";
              };

              opacity = mkOption {
                type = types.addCheck types.float (f: f >= 0.0 && f <= 1.0) // {
                  description = "float between 0.0 and 1.0 (inclusive)";
                };
                description = "Widget background opacity";
                default = null;
                example = 0.75;
              };

              padding = mkOption {
                type = with types; nullOr int;
                description = "Gap between widget border or text";
                default = null;
                example = 4;
              };

              position = {
                x = mkOption {
                  type = with types; nullOr intOrPercentType;
                  description = "X position of widget on screen";
                  default = 0;
                  example = "50%";
                };

                y = mkOption {
                  type = with types; nullOr intOrPercentType;
                  description = "Y position of widget on screen";
                  default = 0;
                  example = "50%";
                };

                xRelative = mkOption {
                  type = with types; nullOr intOrPercentType;
                  description = "X position relative to widget width and height";
                  default = null;
                  example = "-50%";
                };

                yRelative = mkOption {
                  type = with types; nullOr intOrPercentType;
                  description = "Y position relative to widget width and height";
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

      description = "List of widgets to create";

      default = [ ];
      defaultText = literalExpression "[]";

      example = [
        {
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
        }
      ];
    };
  };

  config = mkIf (cfg.enable) {
    systemd.user = (foldr
      (
        widget:
        units:
        lib.recursiveUpdate units {
          targets."stw" = {
            Unit = {
              Description = "All text widgets on the root window";
              PartOf = [ "chrome.target" ];
            };
            Install.WantedBy = [ "chrome.target" ];
          };

          services."stw@${widget.name}" = {
            Unit = {
              Description = ''${pkg.meta.description}, instance "${widget.name}"'';
              PartOf = [ "stw.target" ];
              After = [ "picom.service" ];
            };

            Install.WantedBy = [ "stw.target" ];

            Service = {
              Type =
                if widget.update == "none" then
                  "notify"
                else
                  "simple";

              ExecStart =
                let
                  command' = pkgs.writeShellScript "stw-${widget.name}" ''
                    ${lib.optionalString (widget.update == "none") "${pkgs.systemd}/bin/systemd-notify --ready"}
                    exec ${widget.command}
                  '';
                in
                "${stw}"
                + lib.optionalString widget.window.top " -t"
                + lib.optionalString (widget.window.position.x != null) " -x ${builtins.toString widget.window.position.x}"
                + lib.optionalString (widget.window.position.y != null) " -y ${builtins.toString widget.window.position.y}"
                + lib.optionalString (widget.window.position.xRelative != null) " -X ${builtins.toString widget.window.position.xRelative}"
                + lib.optionalString (widget.window.position.yRelative != null) " -Y ${builtins.toString widget.window.position.yRelative}"
                + lib.optionalString (widget.text.align != null) " -a ${builtins.head (lib.stringsToCharacters widget.text.align)}"
                + lib.optionalString (widget.text.color != null) " -f ${widget.text.color}"
                + lib.optionalString (widget.window.color != null) " -b ${widget.window.color}"
                + lib.optionalString (widget.text.font != null) " -F ${widget.text.font}"
                + lib.optionalString (widget.window.padding != null) " -B ${builtins.toString widget.window.padding}"
                + " -p ${builtins.toString widget.update}"
                + lib.optionalString (widget.window.opacity != null) " -A ${builtins.toString widget.window.opacity}"
                + " -- ${command'}"
              ;

              ExecReload = "${pkgs.procps}/bin/kill -ALRM $MAINPID";
            };
          };
        }
      )
      {
        targets.stw = {
          Unit = {
            Description = "All text widgets on the root window";
            PartOf = [ "chrome.target" "default.target" ];
          };

          Install.WantedBy = [ "chrome.target" "default.target" ];
        };
      }
      cfg.widgets
    );
  };
}



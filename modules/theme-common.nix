{ lib
, config
, mkThemeColorOption
, ...
}:
let
  inherit mkThemeColorOption;

  inherit (lib)
    types

    mapAttrs'
    mkAliasOptionModule
    mkOption
    nameValuePair
    optionalAttrs
    ;

  inherit (config.lib) somasis;

  cfg = config.theme;
in
{
  options.theme = {
    allowCustomXresources = mkOption {
      type = types.bool;
      default = true;
    };

    colors = mkOption {
      description = ''
        Colors.
      '';

      type = types.attrsOf types.anything;

      default = {
        # Default Linux virtual terminal colors.
        background = mkThemeColorOption "background" "#000000";
        foreground = mkThemeColorOption "foreground" "#b2b2b2";

        black = mkThemeColorOption "black" "#000000";
        red = mkThemeColorOption "red" "#b21818";
        green = mkThemeColorOption "green" "#18b218";
        yellow = mkThemeColorOption "yellow" "#b26818";
        blue = mkThemeColorOption "blue" "#1818b2";
        magenta = mkThemeColorOption "magenta" "#b218b2";
        cyan = mkThemeColorOption "cyan" "#18b2b2";
        white = mkThemeColorOption "white" "#b2b2b2";

        brightBlack = mkThemeColorOption "brightBlack" "#686868";
        brightRed = mkThemeColorOption "brightRed" "#ff5454";
        brightGreen = mkThemeColorOption "brightGreen" "#54ff54";
        brightYellow = mkThemeColorOption "brightYellow" "#ffff54";
        brightBlue = mkThemeColorOption "brightBlue" "#5454ff";
        brightMagenta = mkThemeColorOption "brightMagenta" "#ff54ff";
        brightCyan = mkThemeColorOption "brightCyan" "#54ffff";
        brightWhite = mkThemeColorOption "brightWhite" "#ffffff";
      };
    };
  };

  # imports = [
  #   (mkAliasOptionModule [ "theme" "colors" "color0" ] [ "theme" "colors" "black" ])
  #   (mkAliasOptionModule [ "theme" "colors" "color1" ] [ "theme" "colors" "red" ])
  #   (mkAliasOptionModule [ "theme" "colors" "color2" ] [ "theme" "colors" "green" ])
  #   (mkAliasOptionModule [ "theme" "colors" "color3" ] [ "theme" "colors" "yellow" ])
  #   (mkAliasOptionModule [ "theme" "colors" "color4" ] [ "theme" "colors" "blue" ])
  #   (mkAliasOptionModule [ "theme" "colors" "color5" ] [ "theme" "colors" "magenta" ])
  #   (mkAliasOptionModule [ "theme" "colors" "color6" ] [ "theme" "colors" "cyan" ])
  #   (mkAliasOptionModule [ "theme" "colors" "color7" ] [ "theme" "colors" "white" ])
  #   (mkAliasOptionModule [ "theme" "colors" "color8" ] [ "theme" "colors" "brightBlack" ])
  #   (mkAliasOptionModule [ "theme" "colors" "color9" ] [ "theme" "colors" "brightRed" ])
  #   (mkAliasOptionModule [ "theme" "colors" "color10" ] [ "theme" "colors" "brightGreen" ])
  #   (mkAliasOptionModule [ "theme" "colors" "color11" ] [ "theme" "colors" "brightYellow" ])
  #   (mkAliasOptionModule [ "theme" "colors" "color12" ] [ "theme" "colors" "brightBlue" ])
  #   (mkAliasOptionModule [ "theme" "colors" "color13" ] [ "theme" "colors" "brightMagenta" ])
  #   (mkAliasOptionModule [ "theme" "colors" "color14" ] [ "theme" "colors" "brightCyan" ])
  #   (mkAliasOptionModule [ "theme" "colors" "color15" ] [ "theme" "colors" "brightWhite" ])
  # ];

  config = {
    xresources.properties = with cfg.colors; {
      "*background" = background;
      "*foreground" = foreground;

      "*accent" = accent;
      "*colorAccent" = accent;

      "*color0" = black;
      "*color1" = red;
      "*color2" = green;
      "*color3" = yellow;
      "*color4" = blue;
      "*color5" = magenta;
      "*color6" = cyan;
      "*color7" = white;
      "*color8" = brightBlack;
      "*color9" = brightRed;
      "*color10" = brightGreen;
      "*color11" = brightYellow;
      "*color12" = brightBlue;
      "*color13" = brightMagenta;
      "*color14" = brightCyan;
      "*color15" = brightWhite;

      "*colorBlack" = black;
      "*colorRed" = red;
      "*colorGreen" = green;
      "*colorYellow" = yellow;
      "*colorBlue" = blue;
      "*colorMagenta" = magenta;
      "*colorCyan" = cyan;
      "*colorWhite" = white;
      "*colorBrightBlack" = brightBlack;
      "*colorBrightRed" = brightRed;
      "*colorBrightGreen" = brightGreen;
      "*colorBrightYellow" = brightYellow;
      "*colorBrightBlue" = brightBlue;
      "*colorBrightMagenta" = brightMagenta;
      "*colorBrightCyan" = brightCyan;
      "*colorBrightWhite" = brightWhite;
    }
    // optionalAttrs (cfg.allowCustomXresources) (mapAttrs' (n: v: nameValuePair "*${n}" v) cfg.colors)
    ;
  };
}

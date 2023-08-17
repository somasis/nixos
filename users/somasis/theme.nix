{ lib
, config
, ...
}:
let
  theme.colors = rec {
    # Arc color scheme (dark)
    darkForeground = "#e0eaf0";
    darkBackground = "#2f343f";
    darkCursorColor = lightForeground;
    darkBorderColor = "#2b2e39";
    darkSidebarColor = "#353946";

    # Arc color scheme (light)
    lightForeground = "#696d78";
    lightBackground = "#f5f6f7";
    lightCursorColor = darkBackground;
    lightBorderColor = "#cfd6e6";

    colorAccent = "#5294e2";
    color0 = "#755f5f";
    color1 = "#cf4342";
    color2 = "#acc044";
    color3 = "#ef9324";
    color4 = "#438dc5";
    color5 = "#c54d7a";
    color6 = "#499baf";
    color7 = "#d8c7c7";
    color8 = "#937474";
    color9 = "#fe6262";
    color10 = "#c4e978";
    color11 = "#f8dc3c";
    color12 = "#96c7ec";
    color13 = "#f97cac";
    color14 = "#30d0f2";
    color15 = "#e0d6d6";

    foreground = darkForeground;
    background = darkBackground;
    cursorColor = darkCursorColor;
    borderColor = darkBorderColor;
    sidebarColor = darkSidebarColor;
  };
in
{
  _module.args.theme = theme;
  xresources.properties = lib.mapAttrs' (n: v: lib.nameValuePair "*${n}" v) theme.colors;
}

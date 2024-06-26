{ config
, ...
}: {
  theme.colors = rec {
    # Arc color scheme (dark)
    darkForeground = "#e0eaf0";
    darkBackground = "#2f343f";
    darkCursor = lightForeground;
    darkBorder = "#2b2e39";
    darkSidebar = "#3f434f";

    # Arc color scheme (light)
    lightForeground = "#696d78";
    lightBackground = "#f5f6f7";
    lightCursor = darkBackground;
    lightBorder = "#cfd6e6";

    lightMenuForeground = "#5c616c";
    lightMenuBackground = "#ffffff";
    lightMenuBorder = "#dcdfe3";
    lightMenuSelectedForeground = "#ffffff";
    lightMenuSelectedBackground = accent;
    lightMenuDisabledForeground = "#a6a8ae";
    lightMenuDisabledBackground = "#5c616c";
    lightTooltipForeground = "#bac3cf";
    lightTooltipBackground = "#474d5d";

    # Match Arc-Darker GTK theme
    foreground = darkForeground;
    background = darkBackground;
    cursor = darkCursor;
    border = darkBorder;
    sidebar = darkSidebar;
    menuBackground = lightMenuBackground;
    menuForeground = lightMenuForeground;
    menuBorder = lightMenuBorder;
    menuSelectedBackground = lightMenuSelectedBackground;
    menuSelectedForeground = lightMenuSelectedForeground;
    menuDisabledForeground = lightMenuDisabledForeground;
    menuDisabledBackground = lightMenuDisabledBackground;
    tooltipBackground = lightTooltipBackground;
    tooltipForeground = lightTooltipForeground;

    errorBackground = red;
    errorForeground = "#ffffff";
    warningBackground = yellow;
    warningForeground = "#ffffff";
    infoBackground = accent;
    infoForeground = "#ffffff";

    accent = "#5294e2";

    black = "#755f5f";
    red = "#cf4342";
    green = "#acc044";
    yellow = "#ef9324";
    blue = "#438dc5";
    magenta = "#c54d7a";
    cyan = "#499baf";
    white = "#d8c7c7";
    brightBlack = "#937474";
    brightRed = "#fe6262";
    brightGreen = "#c4e978";
    brightYellow = "#f8dc3c";
    brightBlue = "#96c7ec";
    brightMagenta = "#f97cac";
    brightCyan = "#30d0f2";
    brightWhite = "#e0d6d6";
  };
}

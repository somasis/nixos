{ config
, pkgs
, ...
}: {
  home.persistence."/persist${config.home.homeDirectory}".directories = [
    # "etc/qt5ct"
    "etc/Kvantum"
  ];

  home.packages = [
    pkgs.papirus-icon-theme
    pkgs.qogir-icon-theme

    # GTK theming
    pkgs.arc-theme

    # Qt theming
    pkgs.libsForQt5.qtstyleplugin-kvantum
    # pkgs.libsForQt5.qt5ct
    pkgs.arc-kde-theme
  ];

  xresources.properties =
    let
      darkForeground = "#e0eaf0";
      darkBackground = "#2f343f";
      darkCursorColor = lightForeground;
      darkBorderColor = "#2b2e39";
      lightForeground = "#696d78";
      lightBackground = "#f5f6f7";
      # lightCursorColor = darkBackground;
      lightBorderColor = "#cfd6e6";
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
    in
    {
      # "Xft.dpi" = 144; # 96 * 1.5
      "Xft.antialias" = 1;
      "Xft.hinting" = 1;
      # "Xft.hintstyle" = "hintslight";
      "Xft.rgba" = "rgb";

      # "*faceName" = "monospace";

      # Arc color scheme (light)
      "*lightForeground" = lightForeground;
      "*lightBackground" = lightBackground;
      "*lightCursorColor" = darkBackground;
      "*lightBorderColor" = lightBorderColor;

      # Arc color scheme (dark)
      "*darkForeground" = darkForeground;
      "*darkBackground" = darkBackground;
      "*darkCursorColor" = lightForeground;
      "*darkBorderColor" = darkBorderColor;

      "*foreground" = darkForeground;
      "*background" = darkBackground;
      "*cursorColor" = darkCursorColor;
      "*borderColor" = darkBorderColor;

      "*color0" = color0;
      "*color1" = color1;
      "*color2" = color2;
      "*color3" = color3;
      "*color4" = color4;
      "*color5" = color5;
      "*color6" = color6;
      "*color7" = color7;
      "*color8" = color8;
      "*color9" = color9;
      "*color10" = color10;
      "*color11" = color11;
      "*color12" = color12;
      "*color13" = color13;
      "*color14" = color14;
      "*color15" = color15;
      "*colorAccent" = "#5294e2";
      # "*colorAccent" = color3;

      "panel.background" = darkBackground;
      # "panel.font" = "-misc-spleen-medium-*-normal-*-24-*-*-*-*-*-*-*";
      # "panel.boldFont" = "-misc-spleen-medium-*-normal-*-24-*-*-*-*-*-*-*";
      "panel.font" = "monospace:size=10";
      "panel.font2" = "monospace:size=10:style=bold";
      "panel.font3" = "monospace:size=10:style=light";
      "panel.font4" = "monospace:size=10:style=heavy";
    };

  services.xsettingsd = {
    enable = true;
    settings = {
      "Net/ThemeName" = config.gtk.theme.name;
      "Net/IconThemeName" = config.gtk.iconTheme.name;
      "Gtk/CursorThemeName" = config.home.pointerCursor.name;
      "Gtk/FontName" = config.gtk.font.name;
      "Gtk/FontSize" = config.gtk.font.size;

      "Net/EnableEventSounds" = 0;
      "Net/EnableInputFeedbackSounds" = 0;
      "Gtk/EnableAnimations" = 0;
      "Gtk/OverlayScrolling" = false;

      "Gtk/ApplicationPreferDarkTheme" = false;
      "Gtk/PrimaryButtonWarpsSlider" = true;
      "Gtk/MenuImages" = 1;
    };
  };

  home.pointerCursor = {
    name = "Hackneyed";
    package = pkgs.hackneyed;
    size = 32;

    x11.enable = true;
    gtk.enable = true;
  };

  # Requires dconf.
  gtk = {
    enable = true;
    iconTheme.name = "Papirus";
    iconTheme.package = pkgs.papirus-icon-theme;
    theme.name = "Arc-Darker";
    theme.package = pkgs.arc-theme;
    font.name = "sans";
    font.size = 10;

    gtk2.configLocation = "${config.xdg.configHome}/gtk-2.0/gtkrc";

    gtk3 = {
      extraConfig = {
        gtk-cursor-blink = true;
        gtk-cursor-blink-time = 750;
        gtk-cursor-blink-timeout = 0;
        gtk-cursor-aspect-ratio = "0.05";
      };
    };

    gtk4.extraConfig = {
      gtk-cursor-blink = false;
      gtk-cursor-blink-time = 750;
      gtk-cursor-blink-timeout = 0;
      gtk-cursor-aspect-ratio = "0.05";
    };
  };

  services.dunst.iconTheme = {
    name = config.gtk.iconTheme.name;
    package = config.gtk.iconTheme.package;
    size = "32x32";
  };

  # Necessary to make Qt apps not scale like shit
  home.sessionVariables = {
    QT_AUTO_SCREEN_SCALE_FACTOR = 0;
    QT_AUTO_SCREEN_SCALE_FACTORS = 1.5;

    QT_STYLE_OVERRIDE = "${config.qt.style.name}"; # TODO: why is this necessary

    # QT_QPA_PLATFORMTHEME = "qt5ct";
    # QT_SCALE_FACTOR = "1.5";
    # QT_FONT_DPI = config.xresources.properties."Xft.dpi";
    # QT_AUTO_SCREEN_SCALE_FACTOR=0 QT_SCALE_FACTOR= QT_SCREEN_SCALE_FACTORS=1.5 QT_FONT_DPI=
  };

  qt = {
    enable = true;
    style = {
      name = "kvantum";
      package = pkgs.libsForQt5.kvantum;
    };
  };
}

{ config
, theme
, pkgs
, ...
}:
{
  persist.directories = [
    { method = "symlink"; directory = "etc/Kvantum"; }
    { method = "symlink"; directory = "etc/qt5ct"; }
    { method = "symlink"; directory = "etc/qt6ct"; }
  ];

  home.packages = [
    pkgs.libsForQt5.qt5ct
    pkgs.qt6Packages.qt6ct

    pkgs.papirus-icon-theme

    # GTK theming
    pkgs.arc-theme

    # Qt theming
    pkgs.libsForQt5.qtstyleplugin-kvantum
    pkgs.qt6Packages.qtstyleplugin-kvantum
    pkgs.libsForQt5.qtstyleplugins
    pkgs.arc-kde-theme

    # TODO Disable for now until they're in nixpkgs
    # # toki pona
    # pkgs.nasin-nanpa
    # pkgs.linja-sike
    # pkgs.linja-pi-pu-lukin
    # pkgs.linja-pona
    # pkgs.linja-suwi
    # pkgs.linja-pi-tomo-lipu
    # pkgs.linja-wawa
    # pkgs.linja-luka
    # pkgs.linja-pimeja-pona
    # pkgs.sitelen-seli-kiwen

    # pkgs.raleway
    # pkgs.roboto
  ];

  # See <configuration.nix> for actual font settings; this is just to make fontconfig
  # see the fonts installed by home-manager.
  fonts.fontconfig.enable = true;

  xresources.properties = {
    # "Xft.dpi" = 144; # 96 * 1.5
    "Xft.antialias" = 1;
    "Xft.hinting" = 1;
    # "Xft.hintstyle" = "hintslight";
    "Xft.rgba" = "rgb";

    # "*faceName" = "monospace";
    "panel.background" = theme.colors.darkBackground;
    # "panel.font" = "-misc-spleen-medium-*-normal-*-24-*-*-*-*-*-*-*";
    # "panel.boldFont" = "-misc-spleen-medium-*-normal-*-24-*-*-*-*-*-*-*";
    "panel.font1" = "monospace:size=10";
    "panel.font2" = "monospace:size=10:style=bold";
    "panel.font3" = "monospace:size=10:style=light";
    "panel.font4" = "monospace:size=10:style=heavy";
    "panel.font5" = "emoji:size=10";
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

    gtk3.extraConfig = {
      gtk-cursor-blink = true;
      gtk-cursor-blink-time = 750;
      gtk-cursor-blink-timeout = 0;
      gtk-cursor-aspect-ratio = "0.10";
    };

    gtk4.extraConfig = {
      gtk-cursor-blink = false;
      gtk-cursor-blink-time = 750;
      gtk-cursor-blink-timeout = 0;
      gtk-cursor-aspect-ratio = "0.10";
    };
  };

  services.dunst.iconTheme = {
    inherit (config.gtk.iconTheme) name package;
    size = "24x24";
  };

  home.sessionVariables = {
    # Necessary to make Qt apps not scale like shit
    QT_AUTO_SCREEN_SCALE_FACTOR = 0;
    QT_AUTO_SCREEN_SCALE_FACTORS = 1.5;

    # Not required when using qt{5,6}ct.
    # QT_STYLE_OVERRIDE = config.qt.style.name;

    # Improve Java GUI font rendering (really necessary for using
    # LangaugeTool on LibreOffice)
    _JAVA_OPTIONS = "-Dawt.useSystemAAFontSettings=on";
  };

  qt = {
    enable = true;
    platformTheme = "qtct";
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

      "Gtk/PrimaryButtonWarpsSlider" = true;
      "Gtk/MenuImages" = 1;
    };
  };
}

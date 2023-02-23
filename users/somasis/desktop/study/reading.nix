{ pkgs
, ...
}: {
  programs.zathura = {
    enable = true;
    package = pkgs.zathura.overrideAttrs (oldAttrs: { useMupdf = true; });

    options = {
      selection-clipboard = "clipboard";

      incremental-search = false;
      page-cache-size = 30;
      page-thumbnail-size = 1048576 * 16; # 16M

      window-title-home-tilde = true;
      window-title-page = true;
      statusbar-page-percent = true;
      statusbar-home-tilde = true;

      scroll-page-aware = true;
      advance-pages-per-row = true;
      vertical-center = true;

      page-padding = 0;
      statusbar-h-padding = 6;
      statusbar-v-padding = 10;

      default-bg = "${config.xresources.properties."*background"}";
      default-fg = "${config.xresources.properties."*foreground"}";
      statusbar-bg = "${config.xresources.properties."*background"}";
      statusbar-fg = "${config.xresources.properties."*foreground"}";
      inputbar-bg = "${config.xresources.properties."*lightBackground"}";
      inputbar-fg = "${config.xresources.properties."*lightForeground"}";

      completion-bg = "${config.xresources.properties."*lightBackground"}";
      completion-fg = "${config.xresources.properties."*lightForeground"}";
      completion-highlight-bg = "${config.xresources.properties."*colorAccent"}";
      completion-highlight-fg = "${config.xresources.properties."*foreground"}";

      font = "monospace normal 10";
      recolor-darkcolor = config.xresources.properties."*foreground";
      recolor-lightcolor = config.xresources.properties."*background";
    };

    mappings = {
      "<F1>" = "toggle_statusbar";

      "Space" = "next";
      "Esc" = "next";
      "Left" = "previous";
      "Right" = "next";

      "Tab" = "index";
      "`" = "index";
      "[index] Left" = "navigate_index collapse";
      "[index] Right" = "navigate_index expand";

      "r" = "rotate-cw";
      "S-r" = "rotate-ccw";
      "i" = "recolor";

      "ad" = "first-page-column 1:1"; # odd page spreads
      "S-d" = "first-page-column 1:2"; # even page spreads
    };
  };

  home.persistence."/persist${config.home.homeDirectory}".directories = [
    { method = "symlink"; directory = "share/zathura"; }
  ];

  xdg.mimeApps.defaultApplications = {
    "application/pdf" = "org.pwmt.zathura.desktop";
    "application/epub+zip" = "org.pwmt.zathura.desktop";
  };

  xsession.windowManager.bspwm.rules."Zathura".state = "tiled";

  # home.packages = [
  #   pkgs.foliate
  # ];

  # home.persistence."/cache${config.home.homeDirectory}".directories = [
  #       { method = "symlink"; directory = "var/cache/com.github.johnfactotum.Foliate"; }
  # ];

  # dconf.settings = {
  #   "com/github/johnfactotum/Foliate" = {
  #     footer-left = "none";
  #     footer-right = "location";
  #     selection-action-single = "dictionary";
  #     use-menubar = false;
  #     use-sidebar = true;
  #   };

  #   "com/github/johnfactotum/Foliate/library".use-tracker = false;

  #   "com/github/johnfactotum/Foliate/view" = {
  #     enable-footnote = false;
  #     hyphenate = true;
  #     layout = "auto";
  #     margin = 60;
  #     max-width = 1400;
  #     prefer-dark-theme = false;
  #     skeuomorphism = true;
  #     spacing = 2.0;
  #     use-publisher-font = true;
  #   };

  #   "com/github/johnfactotum/Foliate/window-state".show-sidebar = false;
  # };
}

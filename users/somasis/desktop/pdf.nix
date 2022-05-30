{ config, pkgs, ... }: {
  home.packages = [
    # pkgs.ocrmypdf
    pkgs.mupdf
    pkgs.deskew
  ];

  programs.zathura = {
    enable = true;
    package = pkgs.zathura.overrideAttrs (oldAttrs: { useMupdf = true; });

    options = {
      selection-clipboard = "clipboard";

      scroll-page-aware = true;

      incremental-search = false;

      window-title-home-tilde = true;
      window-title-page = true;
      statusbar-basename = true;
      statusbar-page-percent = true;
      # statusbar-home-tilde = true;

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
    };
    mappings = {
      "<F1>" = "toggle_statusbar";
      # "D" = "first-page-column 1:1";
      # "<C-d>" = "first-page-column 1:2";
    };
  };

  home.persistence."/persist${config.home.homeDirectory}".directories = [
    "share/zathura"
  ];

  xdg.mimeApps.defaultApplications."application/pdf" = "org.pwmt.zathura.desktop";

  xsession.windowManager.bspwm.rules."Zathura".state = "tiled";
}

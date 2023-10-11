{ config
, lib
, pkgs
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

      default-bg = config.theme.colors.background;
      default-fg = config.theme.colors.foreground;
      statusbar-bg = config.theme.colors.background;
      statusbar-fg = config.theme.colors.foreground;
      inputbar-bg = config.theme.colors.lightBackground;
      inputbar-fg = config.theme.colors.lightForeground;

      completion-bg = config.theme.colors.lightBackground;
      completion-fg = config.theme.colors.lightForeground;
      completion-highlight-bg = config.theme.colors.accent;
      completion-highlight-fg = config.theme.colors.foreground;

      font = "monospace normal 10";
      recolor-darkcolor = config.theme.colors.foreground;
      recolor-lightcolor = config.theme.colors.background;
    };

    mappings =
      let
        # this is what we call in the industry a
        # "Really fucking dumb workaround for a lack of well designed configuration
        # mechanism in an open source application I don't know how to modify the source of"
        xdotoolKeyType = pkgs.writeShellScript "xdotool" ''
          set -x
          PATH=${lib.makeBinPath [ pkgs.xdotool ]}:"$PATH"

          window=$(xdotool getactivewindow)

          while [ $# -gt 0 ]; do
              case "$1" in
                  type:*)
                      xdotool type --window "$window" --delay 10 --clearmodifiers "''${1#type:}"
                      ;;
                  key:*)
                      xdotool key --window "$window" --delay 10 --clearmodifiers "''${1#key:}"
                      ;;
              esac
              shift
          done
        '';

        xdotool = args: ''exec ${lib.escapeShellArg "${xdotoolKeyType} ${lib.escapeShellArgs args}"}'';
      in
      {
        "<F1>" = "toggle_statusbar";

        "<Space>" = "navigate next";
        # "<Esc>" = "navigate next";

        "<A-Left>" = "navigate previous";
        "<A-Right>" = "navigate next";

        "Tab" = "toggle_index";
        "`" = "toggle_index";
        "[index] Left" = "navigate_index collapse";
        "[index] Right" = "navigate_index expand";

        "r" = "rotate rotate-cw";
        "R" = "rotate rotate-ccw";
        "i" = "recolor";

        "=" = "adjust_window best-fit";
        "_" = "adjust_window width";

        "d" = xdotool [ "type::set first-page-column 1:2" "key:Return" "key:ctrl+d" ];
        "D" = xdotool [ "type::set first-page-column 1:1" "key:Return" "key:ctrl+d" ];
        "<C-d>" = "toggle_page_mode";
      };
  };

  persist.directories = [{
    method = "symlink";
    directory = "share/zathura";
  }];

  xdg.mimeApps.defaultApplications = {
    "application/pdf" = "org.pwmt.zathura.desktop";
    "application/epub+zip" = "org.pwmt.zathura.desktop";
  };

  xsession.windowManager.bspwm.rules."Zathura".state = "tiled";

  programs.qutebrowser.settings.content.pdfjs = false;
}

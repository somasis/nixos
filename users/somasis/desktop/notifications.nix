{ config
, pkgs
, ...
}: {
  services = {
    dunst = {
      enable = true;

      settings = {
        global = {
          follow = "mouse";

          mouse_left_click = "context";
          mouse_middle_click = "do_action";
          mouse_right_click = "close_current";

          alignment = "left";
          origin = "top-right";
          offset = "0x0";
          width = "(${toString (2256 / 24)},${toString (2256 / 3)})";
          height = 32;

          notification_limit = 12;

          icon_position = "left";
          min_height = "32";
          max_icon_size = "32";

          shrink = false;
          padding = 0;
          horizontal_padding = 0;
          text_icon_padding = 6;
          # horizontal_padding = 8;
          # text_icon_padding = 6;

          frame_width = 0;
          separator_height = 0;
          progress_bar = false;

          idle_threshold = 15;
          show_age_threshold = 5;

          font = "monospace 10";
          line_height = 32;
          markup = "full";

          ignore_newline = false;
          format = ''<span font_weight="heavy">%s</span> %b %p'';
          word_wrap = true;
          ellipsize = "end";

          show_indicators = true;

          sticky_history = true;
          history_length = 128;

          enable_posix_regex = true;
          always_run_script = true;
        };

        urgency_low = {
          background = config.theme.colors.black;
          foreground = config.theme.colors.darkForeground;
          fullscreen = "pushback";
        };

        urgency_normal = {
          background = config.theme.colors.lightBackground;
          foreground = config.theme.colors.lightForeground;
          fullscreen = "pushback";
        };

        urgency_critical = {
          background = config.theme.colors.red;
          foreground = config.theme.colors.background;
          timeout = "0s";
        };

        # Application-specific rules
        # HACK(?) I have to prefix these with zz- so they get sorted after global
        #         and don't get overriden by it.
        zz-z.default_icon = "dialog-information";
      };
    };

    sxhkd.keybindings = {
      # Notifications: show actions for notification
      "super + slash" = "${config.services.dunst.package}/bin/dunstctl context";

      # Notifications: close most recent notification
      "super + shift + slash" = "${config.services.dunst.package}/bin/dunstctl close";

      # Notifications: redisplay last notification in history
      "super + ctrl + slash" = "${config.services.dunst.package}/bin/dunstctl history-pop";
    };
  };

  systemd.user.services.xsecurelock.Service.ExecStartPre = [
    "-${config.services.dunst.package}/bin/dunstctl set-paused true"
  ];

  systemd.user.services.xsecurelock.Service.ExecStopPost = [
    "-${config.services.dunst.package}/bin/dunstctl set-paused false"
  ];

  programs.autorandr.hooks.postswitch."notify" = ''
    ${pkgs.libnotify}/bin/notify-send \
        -a autorandr \
        -i preferences-desktop-display \
        -u low \
        'autorandr' \
        "Switched to profile '$AUTORANDR_CURRENT_PROFILE'."
  '';

  home.packages = [ pkgs.libnotify ];
}

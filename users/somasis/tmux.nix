{ config
, pkgs
, ...
}: {
  home.packages = [ pkgs.tmux ];

  xdg.configFile = {
    "tmux/tmux.conf".text = ''
      # Usage options

      ## Always tell windows we can use 256 colors.
      set-option -g default-terminal "tmux-256color"

      set-option -g mouse on

      ## Set scrollback length.
      set-option -g history-limit 20000

      ## Send xterm(1) focus events to windows running under the server.
      set-option -g focus-events on

      ## Indicate modifiers like shift/alt/ctrl using xterm(1) sequences.
      set-option -g xterm-keys on

      ## Set terminal (client) titles appropriately.
      set-option -g set-titles on
      set-option -g set-titles-string "tmux - #T"

      ## Don't make Esc usage have a delay (which is annoying when using kak(1)).
      set-option -g escape-time 25

      # Style
      ## Status bar colors.
      set-option -g status-left-style             "fg=magenta"
      set-option -g status-right-style            "fg=magenta"
      set-option -g status-style                  "bg=default,fg=magenta"

      ## Pane colors.
      set-option -g pane-active-border-style      "bg=default,fg=magenta"

      ## Window entries (in status bar) colors.
      set-option -g window-status-activity-style  "bg=default,fg=white,bold,reverse"
      set-option -g window-status-bell-style      "bg=default,fg=magenta,bold,reverse"
      set-option -g window-status-current-style   "bg=default,fg=magenta,bold,reverse"
      set-option -g window-status-style           "bg=default,fg=magenta"

      # Status bar

      set-option -g status on
      set-option -g status-interval 5
      set-option -g status-position top
      set-option -g status-justify left

      ## Window format, akin to catgirl(1).
      set-option -g window-status-format          " #I #W "
      set-option -g window-status-separator       ""
      set-option -g window-status-current-format  " #I #T "

      ## Nothing on the left, a simple clock and hostname (no domain) on the right.
      set-option -g status-left                   ""
      set-option -g status-right                  "#h %I:%M %p"
      set-option -g status-left-length            0

      # Windows
      set-option -g monitor-activity on
      set-option -g visual-activity on
      set-option -g renumber-windows on
      set-option -g focus-events on


      # Binds
      bind-key -T root F1     set-option status
    '';

    "tmux/unobtrusive.conf".text = ''
      source-file "$XDG_CONFIG_HOME/tmux/tmux.conf"

      set-option -g status off

      set-option -g exit-empty on

      set-option -g set-titles on                 # Refers to *terminal window title*.

      # Set window title rules.
      set-option -g automatic-rename off
      set-option -g allow-rename off
      set-option -g renumber-windows on

      set-option -g history-limit 0

      set-option -gw xterm-keys on
    '';
  };
}

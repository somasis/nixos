{ pkgs
, ...
}: {
  programs.tmux = {
    enable = true;

    secureSocket = false;

    terminal = "tmux-256color";

    historyLimit = 20000;
    escapeTime = 25;

    plugins = [ pkgs.tmuxPlugins.better-mouse-mode ];

    extraConfig = ''
      set-option -g mouse on
      set-option -s extended-keys on

      # Inform tmux of alacritty's features
      set-option -sa terminal-overrides "alacritty:Tc"
      set-option -sa terminal-features "alacritty:extKeys"

      # Set terminal (client) titles appropriately.
      set-option -g set-titles on
      set-option -g set-titles-string "tmux#{?T,: #T,}"

      # Status bar
      set-option -g status on
      set-option -g status-position top
      set-option -g status-justify left
      set-option -g status-interval 5

      set-option -g status-left ""
      set-option -g status-left-length 0
      set-option -g status-right "#{?DISPLAY,,%I:%M %p}"

      set-option -g status-style "bg=default,fg=magenta"
      set-option -g status-left-style "fg=magenta"
      set-option -g status-right-style "fg=magenta"

      # Windows
      set-option -g monitor-activity on
      set-option -g visual-activity on
      set-option -g renumber-windows on
      set-option -g focus-events on

      set-option -g window-status-style "bg=default,fg=magenta"
      set-option -g window-status-current-style "bg=default,fg=magenta,bold,reverse"
      set-option -g window-status-activity-style "bg=default,fg=white,bold,reverse"
      set-option -g window-status-bell-style "bg=default,fg=magenta,bold,reverse"

      # akin to catgirl(1)
      set-option -g window-status-format " #I #W "
      set-option -g window-status-current-format " #I #T "
      set-option -g window-status-separator ""

      set-option -g pane-active-border-style "bg=default,fg=magenta"

      set-option -g set-clipboard on

      # Binds
      bind-key -T root F1 set-option status
    '';
  };

  xdg.configFile."tmux/unobtrusive.conf".text = ''
    source-file "$XDG_CONFIG_HOME/tmux/tmux.conf"

    set-option -g status off

    set-option -g exit-empty on

    set-option -g set-titles on # Refers to *terminal window title*.

    # Set window title rules.
    set-option -g automatic-rename off
    set-option -g allow-rename off
    set-option -g renumber-windows on

    set-option -g history-limit 0

    set-option -gw xterm-keys on
  '';
}

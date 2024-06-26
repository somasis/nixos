{ config
, lib
, pkgs
, ...
}:
let
  bspc = "${config.xsession.windowManager.bspwm.package}/bin/bspc";
in
{
  xsession.windowManager.bspwm = {
    enable = true;

    settings = {
      # Multihead
      remove_disabled_monitors = true;
      remove_unplugged_monitors = true;
      merge_overlapping_monitors = true;

      # Layout
      borderless_monocle = true;
      gapless_monocle = true;
      single_monocle = true;
      center_pseudo_tiled = true;

      focus_follows_pointer = true;
      split_ratio = 0.5;

      # Appearance
      normal_border_color = config.theme.colors.background;
      active_border_color = config.theme.colors.brightBlack; # used for window on inactive monitor
      focused_border_color = config.theme.colors.accent; # used for window on active monitor
      presel_feedback_color = config.theme.colors.brightYellow;

      border_width = 6;
      window_gap = 24;
      top_padding = 48;

      # Usage
      automatic_scheme = "alternate";

      pointer_modifier = "mod4";
      pointer_action1 = "move";
      pointer_action3 = "resize_corner";

      # Disallow focus stealing.
      ignore_ewmh_focus = true;
    };

    extraConfig = ''
      ${bspc} config external_rules_command "$HOME"/bin/bspwm-rules
    '';

    startupPrograms = lib.mkBefore [
      "${pkgs.systemd}/bin/systemctl --user start window-manager.target"
    ];
  };

  services.picom = {
    enable = true;

    # Remove "Xlib: ignoring invalid extension event 161" errors, fixed in next version (as of 10.2)
    package = pkgs.picom-next;

    backend = "xrender";
    vSync = true;

    shadow = false;
    shadowOffsets = [ (-16) (-16) ];
    shadowOpacity = 1;

    shadowExclude = [
      "bounding_shaped"
      "argb"
      "focused"
      "n:e:stw"

      "class_g = 'firefox' && argb"
      "class_g = 'thunderbird' && argb"

      # Kvantum
      "(_NET_WM_WINDOW_TYPE@:a *= 'MENU' || _NET_WM_WINDOW_TYPE@:a *= 'COMBO')"
    ];

    settings = {
      shadow-radius = 16;

      detect-client-leader = false;
      detect-client-opacity = true;
      detect-rounded-corners = true;
      mark-ovredir-focused = true;
      mark-wmwin-focused = true;
      use-ewmh-active-win = false;
      xrender-sync-fence = true;

      crop-shadow-to-monitor = true;

      detect-transient = true;
      unredir-if-possible = true;
      no-ewmh-fullscreen = true;

      wintypes = {
        notification = { redir-ignore = true; };
        dock = { clip-shadow-above = false; };
      };

      # Kvantum
      blur-background-exclude = [
        "(_NET_WM_WINDOW_TYPE@:a *= 'MENU' || _NET_WM_WINDOW_TYPE@:a *= 'COMBO')"
      ];

      # allow for inverting individual windows
      # <https://www.reddit.com/r/i3wm/comments/kbw3a5/shortcut_for_inverting_a_windows_colors/>
      invert-color-include = [ "KYLIE_INVERT@:8c = 1" ];
    };
  };

  xsession.profileExtra = lib.mkIf config.xsession.windowManager.bspwm.enable ''
    [ -n "$DISPLAY" ] && export XDG_CURRENT_DESKTOP=bspwm
  '';

  programs.autorandr.hooks = {
    postswitch.window-manager = lib.mkIf config.xsession.windowManager.bspwm.enable ''
      ${bspc} query -M \
          | ${pkgs.xe}/bin/xe ${bspc} monitor {} \
              -d  "⠂" "⠒" "⠖" "⠶" "⢶"
              # 1 2 3 4 5
    '';

    postswitch.compositing = lib.mkIf config.services.picom.enable ''
      ${pkgs.systemd}/bin/systemctl --user try-restart picom.service
    '';
  };

  home.activation.compositing = lib.mkIf config.services.picom.enable (lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    if ${pkgs.procps}/bin/pgrep -u "$USER" picom >/dev/null 2>&1; then
        $DRY_RUN_CMD ${pkgs.procps}/bin/pkill -USR1 picom
    fi
  '');

  systemd.user = {
    targets = {
      window-manager = {
        Unit = {
          Description = "Services that constitute a fully-working window manager";
          # PartOf = [ "graphical-session.target" ];
          After = [ "graphical-session-pre.target" "graphical-session.target" ];
          Requires = [ "graphical-session-pre.target" "graphical-session.target" ];
          # Before = [ "panel.service" "tray.target" ];
        };
        # Install.WantedBy = [ "graphical-session.target" ];
      };

      lock.Unit = {
        Conflicts = [ "picom.service" ];
        OnSuccess = [ "picom.service" ];
      };
    };

    services = {
      picom = {
        Install.WantedBy = lib.mkForce [ "window-manager.target" ];
        Unit.PartOf = lib.mkForce [ "window-manager.target" ];
      };

      bspwm-react = {
        Unit.Description = "React to bspwm(1) events";
        Service.Type = "simple";
        Service.ExecStart = "${config.home.homeDirectory}/bin/bspwm-react";
        Unit.PartOf = [ "window-manager.target" ];
        Install.WantedBy = [ "window-manager.target" ];
      };

      bspwm-urgent = {
        Unit.Description = pkgs.bspwm-urgent.meta.description;
        Service.Type = "simple";
        Service.ExecStart = lib.getExe pkgs.bspwm-urgent;
        Unit.PartOf = [ "window-manager.target" ];
        Install.WantedBy = [ "window-manager.target" ];
      };
      # xsecurelock.Service = {
      #   ExecStartPre = [ "-${pkgs.systemd}/bin/systemctl --user stop picom.service" ];
      #   ExecStopPost = [ "-${pkgs.systemd}/bin/systemctl --user start picom.service" ];
      # };
    };
  };

  home.packages = [
    pkgs.jumpapp
    pkgs.mmutils
    pkgs.wmutils-core
    pkgs.wmutils-opt
  ]
  ++ lib.optionals config.xsession.windowManager.bspwm.enable [
    pkgs.bspwm-center-window

    (pkgs.writeShellScriptBin "bspwm-hide-unhide" ''
      ido() {
          # shellcheck disable=SC2015
          printf '$ %s\n' "$*" >&2 || :
          "$@"
      }

      PATH=${lib.makeBinPath [
        config.xsession.windowManager.bspwm.package
        pkgs.wmutils-core
        pkgs.xdotool
      ]}

      set -eu

      class=''${1:?no class given}; shift
      classname=''${1:?no class name given}; shift
      role=''${1:?no role given}; shift

      wait_for_window() {
          xdotool search \
              --class \
              --classname \
              --role \
              --all \
              --limit 1 \
              --sync \
              "^$class$|^$classname$|^$role$" \
              2>/dev/null
      }

      id=$(wait_for_window)

      if [[ -z "$id" ]]; then
          printf 'error: no windows matching "%s", "%s", and "%s"\n' \
              "$class" "$classname" "$role" \
              >&2
          exit 1
      fi

      bspc node "$id" -g locked=on || :

      if [[ -z "$(lsw "$(printf '0x%x\n' "$id")")" ]]; then # window is unmapped
          mapw -m "$(printf '0x%X\n' "$id")"
          bspc desktop -f "$(bspc query -D -n "$id")"
          bspc node -f "$id"
      else
          mapw -u "$(printf '0x%X\n' "$id")"
      fi
    '')

    (pkgs.writeShellScriptBin "bspwm-hide-or-close" ''
      PATH=${lib.makeBinPath ([ config.xsession.windowManager.bspwm.package pkgs.xdotool ])}

      ido() {
          # shellcheck disable=SC2015
          printf '$ %s\n' "$*" >&2 || :
          "$@"
      }

      # If we're closing a window,

      node=$(bspc query -N -n "$@")
      mapfile -t locked_nodes < <(bspc query -N "$node" -n '.locked')

      # and the window to close is marked locked=on, ...
      done=false
      for locked_node in "''${locked_nodes[@]}"; do
          if [[ "$node" == "$locked_node" ]]; then
              # unmap/minimize it.
              ido xdotool windowunmap --sync "$node"
              done=true
          fi
      done

      if [[ "$done" == "false" ]]; then
          ido bspc node "$node" -c
      fi
    '')
  ];

  services.sxhkd.keybindings = lib.mkMerge [
    (lib.optionalAttrs config.xsession.windowManager.bspwm.enable {
      # Change to desktop {1-10} on focused monitor
      "super + {1-9,0}" = "${bspc} desktop -f focused:'^{1-9,10}'";

      # Send focused node to desktop {1-10} on focused monitor
      "super + shift + {1-9,0}" = "${bspc} node -d focused:'^{1-9,10}'";

      # Send focused node to focused desktop on monitor {1-10}
      "super + ctrl + {1-9,0}" = "${bspc} node -d ^{1-9,10}:focused";

      # Switch to {next,previous} window
      "super + {_,shift} + a" = "${bspc} node -f {next,prev}.!hidden.window";

      # Switch to {next,previous} window of same class
      "super + {_,shift} + tab" = "${bspc} node -f {next,prev}.!hidden.window.same_class";

      # Rotate desktop layout
      "super + {_,shift} + r" = "${bspc} node @/ -R {90,-90}";

      # Close (or hide) window
      "super + w" = "bspwm-hide-or-close";

      # Kill window
      "super + shift + w" = "${bspc} node -k";

      # Set desktop layout to {tiled, monocle}
      "super + m" = "${bspc} desktop -l next";

      # Set window state to {tiled, pseudo-tiled, floating, fullscreen}
      "super + {t,shift + t,f,m}" = "${bspc} node -t {tiled,pseudo_tiled,floating,fullscreen}";

      # Move window to window {left, down, up, right} of current window
      "super + shift + {Left,Down,Up,Right}" = "${bspc} node -s {west,south,north,east}";

      # Focus {previous, next} window on the current desktop
      "super + {Left,Right}" = "${bspc} node -f {prev,next}.local.!hidden.window";

      # Change to {next, previous} window
      "super + {button5,button4}" = "${bspc} node -f {next,prev}.!hidden.window";

      # Change to desktop {1-10} on focused monitor
      "super + shift + {button5,button4}" = "${bspc} desktop -f focused#{next,prev}";
    })

    (lib.optionalAttrs config.services.picom.enable {
      # Invert window
      "super + shift + i" = pkgs.writeShellScript "toggle-window-invert" ''
        xprop -id "$(xdotool getwindowfocus)" -format KYLIE_INVERT 8c \
            -set KYLIE_INVERT "$(
                xprop -id "$(xdotool getwindowfocus)" 8c KYLIE_INVERT \
                    | sed \
                        -e 's/. * = 1. * /0/' \
                        -e 's/. * = 0. * /1/' \
                        -e 's/. * not found.*/1/'
            )"
      '';
    })
  ];
}

{ lib
, config
, pkgs
, ...
}: {
  wayland.windowManager.hyprland = {
    enable = true;

    extraConfig =
      let
        hypr = "${config.xsession.windowManager.hyprland.package}/bin/hyprctl";
      in
      ''
        exec-once=systemctl --user import-environment PATH
        general {
          border_size = 3
          gaps_in = 0
          gaps_out = 12

          col.active_border = ${builtins.replaceStrings ["#"] [""] config.xresources.properties."*color8"}
          col.inactive_border = ${builtins.replaceStrings ["#"] [""] config.xresources.properties."*background"}

          no_cursor_warps = true

          layout = dwindle
        }

        input {
          follow_mouse = 1

          touchpad {
            natural_scroll = true
            clickfinger_behavior = true
          }
        }

        decoration {
          blur = false
          drop_shadow = false
        }

        animations {
          enabled = false
        }

        misc {
          disable_hyprland_logo = true
        }

        # Window management: change to desktop {1-5} on focused monitor
        bind=SUPER,1,workspace,1
        bind=SUPER,2,workspace,2
        bind=SUPER,3,workspace,3
        bind=SUPER,4,workspace,4
        bind=SUPER,5,workspace,5

        # Window management: send focused node to desktop {1-5} on focused monitor
        bind=SUPER + SHIFT,1,movetoworkspacesilent,1
        bind=SUPER + SHIFT,2,movetoworkspacesilent,2
        bind=SUPER + SHIFT,3,movetoworkspacesilent,3
        bind=SUPER + SHIFT,4,movetoworkspacesilent,4
        bind=SUPER + SHIFT,5,movetoworkspacesilent,5

        # Window management: send focused node to focused desktop on monitor {1-5}
        bind=SUPER + SHIFT,1,movewindow,mon:1
        bind=SUPER + SHIFT,2,movewindow,mon:2
        bind=SUPER + SHIFT,3,movewindow,mon:3
        bind=SUPER + SHIFT,4,movewindow,mon:4
        bind=SUPER + SHIFT,5,movewindow,mon:5

        # Window management: switch to {next,previous} window - SUPER,{_,shift} + a
        bind=SUPER,A,cyclenext,
        bind=SUPER + SHIFT,A,cyclenext,prev

        # Window management: rotate desktop layout - SUPER,r
        # bind=SUPER,R,exec,bspc node @/ -R 90
        # bind=SUPER + SHIFT,R,exec,bspc node @/ -R -90

        # Window management: {close, kill} window - SUPER,w, SUPER,shift + w
        bind=SUPER,W,closewindow,
        bind=SUPER + SHIFT,W,killactive,

        # Window management: set desktop layout to {tiled, monocle} - SUPER,m
        # bind=SUPER,M,exec,bspc desktop -l next

        # Window management: toggle {floating, pseudo, fullscreen} state
        bind=SUPER,T,pseudo,
        bind=SUPER,F,togglefloating,
        bind=SUPER,M,fullscreen,

        # Window management: move window to window {left, down, up, right} of current window - SUPER,shift + {left,down,up,right}
        bind=SUPER + SHIFT,Left,movewindow,l
        bind=SUPER + SHIFT,Down,movewindow,d
        bind=SUPER + SHIFT,Up,movewindow,u
        bind=SUPER + SHIFT,Right,movewindow,r

        # Window management: focus {previous, next} window on the current desktop - SUPER,{left,right}
        # bind=SUPER,Left,movefocus,bspc node -f {prev,next}.local.!hidden.window
        # bind=SUPER,Right,movefocus,bspc node -f {prev,next}.local.!hidden.window

        # Window management: change to {next, previous} window - SUPER,{mouse scroll up,mouse scroll down}
        # bind=SUPER,{button5,button4},exec,bspc node -f {next,prev}.!hidden.window

        # Window management: change to desktop {1-10} on focused monitor - SUPER,{mouse forward,mouse backward}
        # bind=SUPER + SHIFT,{button5,button4},exec,bspc desktop -f focused#{next,prev}

        bind=SUPER + ALT,Delete,exec,terminal ${config.programs.htop.package}/bin/htop

        # Hardware: {mute, lower, raise} output volume - fn + {f1,f2,f3}
        bind=,XF86AudioMute,exec,ponymix -t sink toggle
        bind=SUPER,XF86AudioMute,exec,ponymix -t source toggle
        bind=,XF86AudioRaiseVolume,exec,ponymix-snap -t sink increase 5
        bind=,XF86AudioLowerVolume,exec,ponymix-snap -t sink decrease 5
        bind=SUPER,XF86AudioRaiseVolume,exec,ponymix-snap -t source increase 5
        bind=SUPER,XF86AudioLowerVolume,exec,ponymix-snap -t source decrease 5

        bind=SUPER,B,exec,terminal

        # bind=SUPER,grave,exec,dmenu-run
        # bind=SUPER,Return,exec,dmenu-run
        # bind=ALT,F2,exec,dmenu-run

        bindm=SUPER,mouse:272,movewindow
        bindm=SUPER,mouse:273,resizewindow
      '';
  };

  home.sessionVariables = {
    # QT_AUTO_SCREEN_SCALE_FACTOR = "1";
    # QT_AUTO_SCREEN_SCALE_FACTORS = "";
    # QT_WAYLAND_DISABLE_WINDOWDECORATION = "1";
    # QT_QPA_PLATFORM = "wayland;xcb";

    # XDG_CURRENT_DESKTOP = "Hyprland";
    # XDG_SESSION_TYPE = "wayland";
    # XDG_SESSION_DESKTOP = "Hyprland";

    XCURSOR_THEME = "${config.home.pointerCursor.name}";
    XCURSOR_SIZE = "${builtins.toString config.home.pointerCursor.size}";
  };

  # Disable on Wayland
  systemd.user.services.clipmenu.Unit.ConditionEnvironment = [ "!WAYLAND_DISPLAY" ];
  systemd.user.services.dunst.Unit.ConditionEnvironment = [ "!WAYLAND_DISPLAY" ];
  systemd.user.services.panel.Unit.ConditionEnvironment = [ "!WAYLAND_DISPLAY" ];
  systemd.user.services.picom.Unit.ConditionEnvironment = [ "!WAYLAND_DISPLAY" ];
  systemd.user.services.sctd.Unit.ConditionEnvironment = [ "!WAYLAND_DISPLAY" ];
  systemd.user.services.wallpaper.Unit.ConditionEnvironment = [ "!WAYLAND_DISPLAY" ];
  systemd.user.services.xbanish.Unit.ConditionEnvironment = [ "!WAYLAND_DISPLAY" ];
  systemd.user.services.xidlehook.Unit.ConditionEnvironment = [ "!WAYLAND_DISPLAY" ];
  systemd.user.services.xplugd.Unit.ConditionEnvironment = [ "!WAYLAND_DISPLAY" ];
  systemd.user.services.xsettingsd.Unit.ConditionEnvironment = [ "!WAYLAND_DISPLAY" ];
  systemd.user.services.xss-lock.Unit.ConditionEnvironment = [ "!WAYLAND_DISPLAY" ];
  systemd.user.services.xssproxy.Unit.ConditionEnvironment = [ "!WAYLAND_DISPLAY" ];
  systemd.user.targets.stw.Unit.ConditionEnvironment = [ "!WAYLAND_DISPLAY" ];

  services.kanshi = {
    enable = true;
    profiles = {
      "ilo.somas.is".outputs = [
        { criteria = "eDP-1"; scale = 1.5; }
      ];
      "ilo.somas.is:desk" = {
        outputs = [
          { criteria = "eDP-1"; scale = 1.5; }
          { criteria = "DP-1"; scale = 1.0; }
        ];
      };
    };
    systemdTarget = "hyprland-session.target";
  };

  # programs.waybar.enable = true;

  programs.foot = {
    enable = true;
    settings = {
      main = {
        font = "monospace:size=10";

        pad = "0x0";
      };

      scrollback = {
        multiplier = 2;
        lines = 20000;
      };

      cursor = {
        style = "beam";
        blink = true;
        beam-thickness = 0.25;
      };

      colors = {
        foreground = "${builtins.replaceStrings ["#"] [""] config.xresources.properties."*foreground"}";
        background = "${builtins.replaceStrings ["#"] [""] config.xresources.properties."*background"}";
        regular0 = "${builtins.replaceStrings ["#"] [""] config.xresources.properties."*color0"}";
        regular1 = "${builtins.replaceStrings ["#"] [""] config.xresources.properties."*color1"}";
        regular2 = "${builtins.replaceStrings ["#"] [""] config.xresources.properties."*color2"}";
        regular3 = "${builtins.replaceStrings ["#"] [""] config.xresources.properties."*color3"}";
        regular4 = "${builtins.replaceStrings ["#"] [""] config.xresources.properties."*color4"}";
        regular5 = "${builtins.replaceStrings ["#"] [""] config.xresources.properties."*color5"}";
        regular6 = "${builtins.replaceStrings ["#"] [""] config.xresources.properties."*color6"}";
        regular7 = "${builtins.replaceStrings ["#"] [""] config.xresources.properties."*color7"}";
        bright0 = "${builtins.replaceStrings ["#"] [""] config.xresources.properties."*color0"}";
        bright1 = "${builtins.replaceStrings ["#"] [""] config.xresources.properties."*color1"}";
        bright2 = "${builtins.replaceStrings ["#"] [""] config.xresources.properties."*color2"}";
        bright3 = "${builtins.replaceStrings ["#"] [""] config.xresources.properties."*color3"}";
        bright4 = "${builtins.replaceStrings ["#"] [""] config.xresources.properties."*color4"}";
        bright5 = "${builtins.replaceStrings ["#"] [""] config.xresources.properties."*color5"}";
        bright6 = "${builtins.replaceStrings ["#"] [""] config.xresources.properties."*color6"}";
        bright7 = "${builtins.replaceStrings ["#"] [""] config.xresources.properties."*color7"}";
      };
    };
  };
}

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
      normal_border_color = config.xresources.properties."*background";
      active_border_color = config.xresources.properties."*color8"; # used for window on inactive monitor
      focused_border_color = config.xresources.properties."*colorAccent"; # used for window on active monitor
      presel_feedback_color = config.xresources.properties."*color11";

      border_width = 6;
      window_gap = 24;
      top_padding = 48;

      # Usage
      automatic_scheme = "alternate";

      pointer_modifier = "mod4";
      pointer_action1 = "move";
      pointer_action3 = "resize_corner";
    };

    extraConfig = ''
      ${bspc} config "external_rules_command" "${config.home.homeDirectory}/bin/bspwm-rules"
    '';
  };

  xsession.profileExtra = ''
    [ -n "$DISPLAY" ] && export XDG_CURRENT_DESKTOP=bspwm
  '';

  programs.autorandr.hooks.postswitch.bspwm = ''
    ${bspc} query -M --names \
        | ${pkgs.xe}/bin/xe ${bspc} monitor {} -d 1 2 3 4 5
  '';

  # systemd.user.services.bspwm-react = {
  #   Unit.Description = "React to bspwm(1) events";
  #   Service.Type = "simple";
  #   Service.ExecStart = "${config.home.homeDirectory}/bin/bspwm-react";
  #   Unit.PartOf = [ "graphical-session.target" ];
  #   Install.WantedBy = [ "graphical-session.target" ];
  # };

  services.sxhkd.keybindings =
    {
      # Window management: change to desktop {1-10} on focused monitor
      "super + {1-9,0}" = "${bspc} desktop -f focused:'^{1-9,10}'";

      # Window management: send focused node to desktop {1-10} on focused monitor
      "super + shift + {1-9,0}" = "${bspc} node -d focused:'^{1-9,10}'";

      # Window management: send focused node to focused desktop on monitor {1-10}
      "super + ctrl + {1-9,0}" = "${bspc} node -d ^{1-9,10}:focused";

      # Window management: switch to {next,previous} window - super + {_,shift} + a
      "super + {_,shift} + a" = "${bspc} node -f {next,prev}.!hidden.window";

      # Window management: rotate desktop layout - super + r
      "super + {_,shift} + r" = "${bspc} node @/ -R {90,-90}";

      # Window management: {close, kill} window - super + w, super + shift + w
      "super + {_,shift} + w" = "${bspc} node -{c,k}";

      # Window management: set desktop layout to {tiled, monocle} - super + m
      "super + m" = "${bspc} desktop -l next";

      # Window management: set window state to {tiled, pseudo-tiled, floating, fullscreen} - super + {t,shift + t,f,m}
      "super + {t,shift + t,f,m}" = "${bspc} node -t {tiled,pseudo_tiled,floating,fullscreen}";

      # Window management: move window to window {left, down, up, right} of current window - super + shift + {left,down,up,right}
      "super + shift + {Left,Down,Up,Right}" = "${bspc} node -s {west,south,north,east}";

      # Window management: focus {previous, next} window on the current desktop - super + {left,right}
      "super + {Left,Right}" = "${bspc} node -f {prev,next}.local.!hidden.window";

      # Window management: change to {next, previous} window - super + {mouse scroll up,mouse scroll down}
      "super + {button5,button4}" = "${bspc} node -f {next,prev}.!hidden.window";

      # Window management: change to desktop {1-10} on focused monitor - super + {mouse forward,mouse backward}
      "super + shift + {button5,button4}" = "${bspc} desktop -f focused#{next,prev}";
    };
}

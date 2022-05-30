{ inputs, config, pkgs, ... }: {
  home.packages = [
    pkgs.cagebreak
    pkgs.hikari
    pkgs.hyprland
    pkgs.labwc
    pkgs.qtile
    pkgs.river
    pkgs.rivercarro

    (pkgs.dwl.overrideAttrs (
      let
        year = builtins.substring 0 4 (inputs.dwl.lastModifiedDate);
        month = builtins.substring 4 2 (inputs.dwl.lastModifiedDate);
        day = builtins.substring 6 2 (inputs.dwl.lastModifiedDate);
      in
      oldAttrs: {
        name = "dwl";
        version = "unstable-${year}-${month}-${day}";
        src = inputs.dwl;
      }
    ))

    pkgs.kanshi
    pkgs.swaybg
    pkgs.wlr-randr

    pkgs.numix-gtk-theme
  ];

  home.persistence."/persist${config.home.homeDirectory}".directories = [
    "etc/cagebreak"
    "etc/hikari"
    "etc/hypr"
    "etc/labwc"
    "etc/qtile"
    "etc/river"
  ];

  services.kanshi = {
    enable = true;
    profiles = {
      "ilo.somas.is".outputs = [
        { criteria = "eDP-1"; scale = 1.5; }
      ];
      "ilo.somas.is:desk" = {
        outputs = [
          { criteria = "eDP-1"; scale = 1.5; status = "disable"; }
          { criteria = "DP-5"; }
          { criteria = "DP-6"; }
        ];
      };
    };
    # systemdTarget = "graphical-session.target";
  };

  programs.waybar.enable = true;

  programs.foot = {
    enable = true;
    settings = {
      main = {
        font = "monospace:size=10";

        pad = "0x0";
      };

      scrollback = {
        lines = 10000;
        multiplier = 2;
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

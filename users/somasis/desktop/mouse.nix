{ pkgs, ... }: {
  services.unclutter = {
    enable = true;
    timeout = 5;
    extraOptions = [ "exclude-root" "ignore-scrolling" ];
  };

  services.fusuma = {
    enable = true;
    extraPackages = [ pkgs.coreutils pkgs.xdotool ];

    settings = {
      swipe = {
        # Emulate Back/Forward mouse buttons with three-finger swipe left/right
        "3".right.command = "xdotool click --clearmodifiers 8";
        "3".left.command = "xdotool click --clearmodifiers 9";

        # Send Home/End keys with three finger swipe up/down
        # "3".down.command = "xdotool key --clearmodifiers Home";
        # "3".up.command = "xdotool key --clearmodifiers End";
      };
    };
  };

  # systemd.user.services.xbanish = {
  #   Unit = {
  #     Description = "Hide the mouse pointer when typing";
  #     PartOf = [ "graphical-session.target" ];
  #   };
  #   Install.WantedBy = [ "graphical-session.target" ];

  #   Service = {
  #     ExecStart = "${pkgs.xbanish}/bin/xbanish -i all";
  #     Restart = "always";
  #   };
  # };
}

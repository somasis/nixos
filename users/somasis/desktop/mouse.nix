{ pkgs, ... }: {
  services.unclutter = {
    enable = true;
    timeout = 5;
    extraOptions = [ "exclude-root" "ignore-scrolling" ];
  };

  services.fusuma = {
    enable = true;

    package = pkgs.fusuma;
    extraPackages = [ pkgs.coreutils pkgs.gnugrep pkgs.libnotify pkgs.xdotool ];

    settings = {
      swipe = {
        # Emulate Back/Forward mouse buttons with three-finger swipe left/right
        "3".right.command = pkgs.writeShellScript "fusuma-back" ''
          xdotool click --clearmodifiers 8

          id="''${XDG_RUNTIME_DIR:=/run/user/$(id -un)}/fusuma.notification"
          if [ -e "$id" ]; then
              id=$(<"$id")
              notify-send -r "$id" -a fusuma -u low -t 1000 -i gtk-go-back-ltr -e "back"
          else
              notify-send -p -a fusuma -u low -t 1000 -i gtk-go-back-ltr -e "back" > "$id"
          fi
        '';
        "3".left.command = pkgs.writeShellScript "fusuma-forward" ''
          xdotool click --clearmodifiers 9

          id="''${XDG_RUNTIME_DIR:=/run/user/$(id -un)}/fusuma.notification"
          if [ -e "$id" ]; then
              id=$(<"$id")
              notify-send -r "$id" -a fusuma -u low -t 1000 -i gtk-go-forward-ltr -e "fwd"
          else
              notify-send -p -a fusuma -u low -t 1000 -i gtk-go-forward-ltr -e "fwd" > "$id"
          fi
        '';

        # Send Home/End keys with three finger swipe up/down
        # "3".down.command = "xdotool key --clearmodifiers Home";
        # "3".up.command = "xdotool key --clearmodifiers End";
      };
    };
  };
}

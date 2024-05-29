{ config
, lib
, pkgs
, ...
}: {
  console = {
    useXkbConfig = true;

    colors = [
      "000000" # color0:  black; bg
      "cf4342" # color1:  red
      "acc044" # color2:  green
      "ef9324" # color3:  yellow
      "438dc5" # color4:  blue
      "c54d7a" # color5:  magenta
      "499baf" # color6:  cyan
      "d8c7c7" # color7:  grey; fg
      "937474" # color8:  bright black
      "fe6262" # color9:  bright red
      "c4e978" # color10: bright green
      "f8dc3c" # color11: bright yellow
      "96c7ec" # color12: bright blue
      "f97cac" # color13: bright magenta
      "30d0f2" # color14: bright cyan
      "e0d6d6" # color15: bright grey
    ];
  };

  # Only create two virtual terminals, one for Xorg and one for getty.
  services.logind.extraConfig = lib.generators.toKeyValue { } {
    NAutoVTs = 2;
  };

  # Set the keyboard repeat rate to be the same as Xorg's
  systemd.services."serial-getty@".preStart = ''
    ${pkgs.kbd}/bin/kbdrate \
        -r ${toString (config.services.xserver.autoRepeatInterval or 25)} \
        -d ${toString (config.services.xserver.autoRepeatDelay or 660)}
  '';

  # Show the system journal on tty12.
  services.journald.console = "/dev/tty12";
}

{ pkgs, ... }: {
  console = {
    useXkbConfig = true;

    colors = [
      "000000" # color0:  black; bg
      "cf4342" # color1:  red
      "acc044" # color2:  green
      "ef9324" # color3:  yellow
      "438dc5" # color4:  blue
      "c54d7a" # color5:  pink
      "499baf" # color6:  cyan
      "d8c7c7" # color7:  grey; fg
      "937474" # color8:  bright black
      "fe6262" # color9:  bright red
      "c4e978" # color10: bright green
      "f8dc3c" # color11: bright yellow
      "96c7ec" # color12: bright blue
      "f97cac" # color13: bright pink
      "30d0f2" # color14: bright cyan
      "e0d6d6" # color15: bright grey
    ];
  };

  services.kmscon = {
    enable = true;

    hwRender = false;

    extraConfig = ''
      vt=2
      sb-size=10000
      font-size=11
      font-dpi=144

      palette=custom
      palette-background=47,52,63
      palette-foreground=224,234,240
      palette-black=117,95,95
      palette-red=207,67,66
      palette-green=172,192,68
      palette-yellow=239,147,36
      palette-blue=67,141,197
      palette-magenta=197,77,122
      palette-cyan=73,155,175
      palette-light-grey=216,199,199
      palette-dark-grey=147,116,116
      palette-light-red=254,98,98
      palette-light-green=196,233,120
      palette-light-yellow=248,220,60
      palette-light-blue=150,199,236
      palette-light-magenta=249,124,172
      palette-light-cyan=48,208,242
      palette-white=224,214,214
    '';

    fonts = [
      { name = "Iosevka Term"; package = pkgs.iosevka-bin; }
      # { name = "Sarasa Term CL"; package = pkgs.sarasa-gothic; }
      # { name = "Twitter Color Emoji"; package = pkgs.twitter-color-emoji; }
    ];
  };
}

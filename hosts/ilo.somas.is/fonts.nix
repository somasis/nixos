{ pkgs
, lib
, ...
}: {
  fonts = {
    enableDefaultPackages = false;

    packages = [
      pkgs.noto-fonts
      pkgs.noto-fonts-cjk-sans
      pkgs.noto-fonts-cjk-serif

      pkgs.iosevka-bin
      (pkgs.iosevka-bin.override { variant = "Aile"; })
      (pkgs.iosevka-bin.override { variant = "Etoile"; })
      (pkgs.iosevka-bin.override { variant = "Slab"; })
      (pkgs.iosevka-bin.override { variant = "Curly"; })
      (pkgs.iosevka-bin.override { variant = "CurlySlab"; })
      (pkgs.nerdfonts.override { fonts = [ "NerdFontsSymbolsOnly" ]; })

      pkgs.sarasa-gothic # CJK in a style similar to Iosevka

      pkgs.lmodern

      pkgs.linja-luka
      pkgs.linja-namako
      pkgs.linja-pi-pu-lukin
      pkgs.linja-pi-tomo-lipu
      pkgs.linja-pimeja-pona
      pkgs.linja-pona
      pkgs.linja-sike
      pkgs.linja-suwi
      pkgs.nasin-nanpa
      pkgs.sitelen-seli-kiwen

      pkgs.spleen

      pkgs.twitter-color-emoji
    ];

    fontconfig = {
      allowBitmaps = false;
      useEmbeddedBitmaps = true;

      cache32Bit = true;

      antialias = true;
      hinting.enable = true;

      subpixel = {
        rgba = "none";
        lcdfilter = "none";
      };

      defaultFonts = {
        sansSerif = lib.mkForce [
          "Noto Sans"
          "nasin-nanpa"
          "emoji"
        ];
        serif = lib.mkForce [
          "Noto Serif"
          "nasin-nanpa"
          "emoji"
        ];
        monospace = lib.mkForce [
          "Iosevka"
          "Sarasa Term CL"
          "nasin-nanpa"
          "emoji"
        ];
        emoji = lib.mkBefore [ "Twitter Color Emoji" ];
      };
    };
  };

  console = {
    packages = [ pkgs.spleen pkgs.uw-ttyp0 pkgs.uni-vga ];
    font = "${pkgs.spleen}/share/consolefonts/spleen-12x24.psfu";
  };
}

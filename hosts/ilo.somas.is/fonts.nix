{ pkgs
, lib
, ...
}: {
  fonts = {
    enableDefaultFonts = false;

    fonts = [
      pkgs.noto-fonts
      pkgs.inter

      pkgs.iosevka-bin
      # (pkgs.iosevka-bin.override { variant = "sgr-iosevka-term"; })
      (pkgs.iosevka-bin.override { variant = "aile"; })
      (pkgs.iosevka-bin.override { variant = "etoile"; })
      (pkgs.iosevka-bin.override { variant = "slab"; })
      (pkgs.iosevka-bin.override { variant = "curly"; })
      (pkgs.iosevka-bin.override { variant = "curly-slab"; })

      pkgs.sarasa-gothic # CJK in a style similar to Iosevka

      # pkgs.lmodern

      pkgs.nasin-nanpa

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
          "Inter"
          # "Noto Sans"
          # "Sarasa Mono CL"
          "nasin-nanpa"
          "emoji"
        ];
        serif = lib.mkForce [
          "Noto Serif"
          # "Iosevka Etoile"
          # "Sarasa Fixed Slab CL"
          "nasin-nanpa"
          "emoji"
        ];
        monospace = lib.mkForce [
          "Iosevka Term"
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
    # font = "${pkgs.spleen}/share/consolefonts/spleen-12x24.psfu";
    # font = "${pkgs.uni-vga}/share/consolefonts/u_vga16.psf.gz";
    font = "${pkgs.uw-ttyp0}/share/consolefonts/t0-22-uni.psf";
  };
}

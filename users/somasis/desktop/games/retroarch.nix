{ pkgs, config, ... }: {
  home.packages = [
    (pkgs.retroarch.override {
      cores = with pkgs.libretro; [
        stella # Atari - 2600
        virtualjaguar # Atari - Jaguar
        prboom # DOOM
        mame # MAME
        freeintv # Mattel - Intellivision
        mgba # Nintendo - Game Boy Advance
        sameboy # Nintendo - Game Boy / Nintendo - Game Boy Color
        dolphin # Nintendo - GameCube / Nintendo - Wii
        citra # Nintendo - Nintendo 3DS
        mupen64plus # Nintendo - Nintendo 64
        parallel-n64 # Nintendo - Nintendo 64 (Dr. Mario 64)
        melonds # Nintendo - Nintendo DS
        mesen # Nintendo - Nintendo Entertainment System / Nintendo - Family Computer Disk System
        snes9x # Nintendo - Super Nintendo Entertainment System
        # picodrive # Sega - 32X # TODO broken
        flycast # Sega - Dreamcast
        genesis-plus-gx # Sega - Mega-Drive - Genesis
        beetle-saturn # Sega - Saturn
        swanstation # Sony - PlayStation
        pcsx2 # Sony - PlayStation 2
        ppsspp # Sony - PlayStation Portable
      ];
    })
  ];

  xsession.windowManager.bspwm.rules."retroarch" = {
    state = "fullscreen";
    layer = "above";
    monitor = "primary";
  };

  home.persistence."/persist${config.home.homeDirectory}".directories = [
    { directory = "etc/retroarch"; method = "symlink"; }
  ];
}

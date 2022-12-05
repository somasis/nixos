{ pkgs
, ...
}: {
  home.packages = [
    pkgs.line-awesome

    # TODO Disable for now until they're in nixpkgs
    # # toki pona
    # pkgs.nasin-nanpa
    # pkgs.linja-sike
    # pkgs.linja-pi-pu-lukin
    # pkgs.linja-pona
    # pkgs.linja-suwi
    # pkgs.linja-pi-tomo-lipu
    # pkgs.linja-wawa
    # pkgs.linja-luka
    # pkgs.linja-pimeja-pona
    # pkgs.sitelen-seli-kiwen

    # Free replacements for pkgs.corefonts
    # Arial, Times New Roman
    pkgs.noto-fonts-extra
    # # Cambria
    pkgs.caladea
    # # Calibri
    pkgs.carlito
    # Comic Sans MS
    pkgs.comic-relief
    # # Georgia
    pkgs.gelasio
    # Arial Narrow
    pkgs.liberation-sans-narrow
    # Arial, Helvetica, Times New Roman, Courier New
    pkgs.liberation_ttf

    # pkgs.raleway
    # pkgs.roboto
  ];

  # See <configuration.nix> for actual font settings; this is just to make fontconfig
  # see the fonts installed by home-manager.
  fonts.fontconfig.enable = true;
}

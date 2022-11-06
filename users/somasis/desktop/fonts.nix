{ pkgs
, lib
, nixosConfig
, ...
}: {
  home.packages = [
    pkgs.line-awesome

    # Free replacements for pkgs.corefonts
    # # Arial, Times New Roman
    # pkgs.arkpandora_ttf
    # # Cambria
    # pkgs.caladea
    # # Calibri
    # pkgs.carlito
    # # Georgia
    # pkgs.gelasio
    # # Arial Narrow
    # pkgs.liberation-sans-narrow
    # # Arial, Helvetica, Times New Roman, Courier New
    # pkgs.liberation_ttf

    # pkgs.raleway
    # pkgs.roboto
  ]
  ++ (lib.optionals (lib.versionOlder nixosConfig.system.nixos.release "22.05") [
    # toki pona
    pkgs.nasin-nanpa
    pkgs.linja-sike
    pkgs.linja-pi-pu-lukin
    pkgs.linja-pona
    pkgs.linja-suwi
    pkgs.linja-pi-tomo-lipu
    pkgs.linja-wawa
    pkgs.linja-luka
    pkgs.linja-pimeja-pona
    pkgs.sitelen-seli-kiwen
  ])
  ;

  # See <configuration.nix> for actual font settings; this is just to make fontconfig
  # see the fonts installed by home-manager.
  fonts.fontconfig.enable = true;
}

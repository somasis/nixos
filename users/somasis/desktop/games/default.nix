{ config
, pkgs
, ...
}: {
  imports = [
    ./minecraft.nix
    ./retroarch.nix
    ./steam.nix
    ./urbanterror.nix
  ];

  home.packages = [
    # pkgs.koboredux-free
    pkgs.lbreakout2
    pkgs.libsForQt5.kpat
    pkgs.opentyrian
    pkgs.pingus
    pkgs.sgtpuzzles
    pkgs.zaz

    pkgs.pcsx2
  ];

  home.persistence."/persist${config.home.homeDirectory}" = {
    files = [
      "etc/kpatrc"
    ];

    directories = [
      ".lbreakout2"
      ".zaz"
      "etc/opentyrian"
      "etc/pingus-0.8"
      "share/kpat"

      "etc/PCSX2"
    ];
  };
}

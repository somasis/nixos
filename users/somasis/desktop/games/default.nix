{ config
, pkgs
, ...
}:
{
  imports = [
    ./minecraft.nix
    # TODO ./nx.nix
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
    # pkgs.zaz # TODO broken because of SDL.h

    pkgs.pcsx2
  ];

  persist = {
    files = [ "etc/kpatrc" ];

    directories = [
      { method = "symlink"; directory = ".lbreakout2"; }
      { method = "symlink"; directory = ".zaz"; }
      { method = "symlink"; directory = "etc/PCSX2"; }
      { method = "symlink"; directory = "etc/opentyrian"; }
      { method = "symlink"; directory = "etc/pingus-0.8"; }
      { method = "symlink"; directory = "share/kpat"; }
    ];
  };
}

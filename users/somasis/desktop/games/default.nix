{ config
, lib
, osConfig
, pkgs
, ...
}: {
  imports = [
    ./minecraft.nix
    # TODO ./nx.nix
    ./retroarch.nix
    # ./steam.nix
    ./urbanterror.nix
  ];

  home.packages = [
    pkgs.lbreakout2
    pkgs.lbreakouthd
    pkgs.kdePackages.kpat
    pkgs.opentyrian
    # pkgs.pingus
    pkgs.sgt-puzzles
    pkgs.zaz

    pkgs.pcsx2

    pkgs.space-cadet-pinball
  ];

  home.shellAliases = lib.mkIf osConfig.programs.gamemode.enable {
    pcsx2 = "gamemoderun pcsx2-qt -fullscreen -bigpicture";
  };

  persist = {
    files = [ "etc/kpatrc" ];

    directories = [
      { method = "symlink"; directory = ".lgames"; }
      { method = "symlink"; directory = ".lbreakouthd"; }
      { method = "symlink"; directory = ".zaz"; }
      { method = "symlink"; directory = config.lib.somasis.xdgConfigDir "PCSX2"; }
      { method = "symlink"; directory = config.lib.somasis.xdgConfigDir "opentyrian"; }
      { method = "symlink"; directory = config.lib.somasis.xdgConfigDir "pingus-0.8"; }
      { method = "symlink"; directory = config.lib.somasis.xdgDataDir "kpat"; }
    ];
  };

  systemd.user.services.joystickwake = {
    Service.Type = "simple";
    Service.ExecStart = lib.getExe pkgs.joystickwake;
    Install.WantedBy = [ "game.target" ];
    Unit.PartOf = [ "game.target" ];
  };
}

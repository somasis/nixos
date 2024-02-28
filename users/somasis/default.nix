{ self
, inputs
, config
, lib
, pkgs
, osConfig
, ...
}:
{
  imports = [
    ./commands
    ./editor
    ./git
    ./modules
    ./shell

    ./less.nix
    ./locale.nix
    ./man.nix
    ./monitor.nix
    ./pass.nix
    ./skim.nix
    ./ssh.nix
    ./syncthing.nix
    ./text-manipulation.nix
    ./theme.nix
    ./tmux.nix
    ./xdg.nix
  ];

  persist = {
    allowOther = true;
    directories = [{ method = "symlink"; directory = "bin"; }];
  };

  cache.allowOther = true;
  log.allowOther = true;

  nixpkgs = {
    config =
      lib.recursiveUpdate
        (osConfig.nixpkgs.config or { })
        {
          allowUnfree = true;
        }
    ;

    overlays =
      # lib.lists.unique (
      (osConfig.nixpkgs.overlays or [ ])
      ++ lib.optional ((self.overlays.default or null) != null) self.overlays.default
      ++ [
        (final: prev: {
          stable = inputs.nixpkgsStable.legacyPackages.${pkgs.stdenv.hostPlatform.system};
        })
      ]
      #)
    ;
  };

  home.packages = [
    pkgs.dateutils
    pkgs.execline
    pkgs.file
    pkgs.jdupes
    pkgs.limitcpu
    pkgs.lr
    pkgs.ltrace
    pkgs.nq
    pkgs.pigz
    pkgs.pv
    pkgs.rlwrap
    pkgs.rsync
    pkgs.s6
    pkgs.s6-dns
    pkgs.s6-linux-init
    pkgs.s6-linux-utils
    pkgs.s6-networking
    pkgs.s6-portable-utils
    pkgs.s6-rc
    pkgs.snooze
    pkgs.strace
    pkgs.teip
    pkgs.trurl
    pkgs.uq
    pkgs.xe
    pkgs.xsv
    pkgs.xz
    pkgs.zstd

    # moreutils's /bin/ts conflicts with outils.
    (pkgs.symlinkJoin {
      name = "outils-moreutils";
      paths = [ pkgs.outils pkgs.moreutils ];
    })
  ];

  xdg.configFile."curlrc".text = lib.generators.toKeyValue { } {
    show-error = true;
    fail-early = true;

    globoff = true;
    disallow-username-in-url = true;

    connect-timeout = 60;
    retry = 10;
    retry-delay = 5;

    compressed = true;

    parallel = true;
    parallel-max = 4;

    user-agent = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/97.0.4692.99 Safari/537.36";
  };

  systemd.user.startServices = true;

  home.sessionPath = [ "$HOME/bin" ];

  home.sessionVariables."SYSTEMD_PAGER" = "cat";

  home.stateVersion = "22.11";
}

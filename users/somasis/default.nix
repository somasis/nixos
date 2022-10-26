{ config
, pkgs
, ...
}:
{
  imports = [
    ./commands
    ./git
    ./kakoune
    ./modules
    ./shell

    ./htop.nix
    ./less.nix
    ./man.nix
    ./mess.nix
    ./pass.nix
    ./skim.nix
    ./spell.nix
    ./ssh.nix
    ./syncthing.nix
    ./tmux.nix
    ./xdg.nix
  ];

  home.persistence."/persist${config.home.homeDirectory}" = {
    directories = [
      "bin"
      "diary"
      "logs"
      "shared"
      { directory = "src"; method = "symlink"; }
      "study"
      "tracks"

      "etc/tmux"
    ];

    allowOther = true;
  };

  home.persistence."/cache${config.home.homeDirectory}" = {
    directories = [
      "etc/borg"

      "var/cache/nix"
      "var/cache/nix-index"
    ];

    allowOther = true;
  };

  home.keyboard.options = [ "compose:ralt" ];

  home.packages = [
    pkgs.rlwrap

    pkgs.wmutils-core
    pkgs.wmutils-opt
    pkgs.mmutils

    (
      pkgs.stdenv.mkDerivation rec {
        pname = "execshell";
        version = "20201101";

        src = pkgs.fetchFromGitHub {
          owner = "sysvinit";
          repo = "execshell";
          rev = "b0b41d50cdb09f26b7f31e960e078c0500c661f5";
          hash = "sha256-TCk9U396NoZL1OvAddcMa2IFyvyDs/3daKv5IRxkRYE=";
          fetchSubmodules = true;
        };

        buildInputs = [ pkgs.skalibs pkgs.execline ];

        installPhase = ''
          install -m0755 -D execshell $out/bin/execshell
        '';

        makeFlags = [ "CC:=$(CC)" ];

        meta = with pkgs.lib; {
          description = "Proof of concept execline interactive REPL";
          license = with licenses; [ isc bsd2 ];
          maintainers = with maintainers; [ somasis ];
          platforms = platforms.all;
        };
      }
    )

    pkgs.pigz
    pkgs.xz
    pkgs.zstd

    pkgs.jdupes
    pkgs.strace
    pkgs.xsv

    pkgs.moreutils
    pkgs.dateutils
    pkgs.teip

    pkgs.nq
    pkgs.jq
    pkgs.snooze
    pkgs.xe

    # NOTE Not in NixOS 22.05
    pkgs.outils

    pkgs.extrace
    pkgs.uq
    pkgs.ltrace
    pkgs.file
    pkgs.pv

    pkgs.rsync

    pkgs.execline
    pkgs.s6
    pkgs.s6-rc
    pkgs.s6-networking
    pkgs.s6-dns
    pkgs.s6-linux-init
    pkgs.s6-linux-utils
    pkgs.s6-portable-utils

    (pkgs.writeShellApplication {
      name = "stderred";

      runtimeInputs = [ pkgs.stderred ];

      text = ''
        export LD_PRELOAD=${pkgs.stderred}/lib/libstderred.so
        exec "$@"
      '';
    })
  ];

  programs.jq.enable = true;

  systemd.user.startServices = true;

  home.sessionPath = [ "$HOME/bin" ];

  home.sessionVariables."SYSTEMD_PAGER" = "cat";

  programs.nix-index = {
    enable = true;
    enableBashIntegration = false;
  };

  home.stateVersion = "21.11";
}

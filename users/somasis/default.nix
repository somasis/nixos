{ config
, pkgs
, nixosConfig
, lib
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

    pkgs.dateutils
    pkgs.extrace
    pkgs.file
    pkgs.jdupes
    pkgs.jq
    pkgs.lr
    pkgs.moreutils
    pkgs.nq
    pkgs.outils
    pkgs.pv
    pkgs.snooze
    pkgs.teip
    pkgs.uq
    pkgs.xe
    pkgs.xsv

    pkgs.strace
    pkgs.ltrace

    pkgs.rsync

    pkgs.execline
    pkgs.s6
    pkgs.s6-rc
    pkgs.s6-networking
    pkgs.s6-dns
    pkgs.s6-linux-init
    pkgs.s6-linux-utils
    pkgs.s6-portable-utils

    # autocurl - curl for use by background/automatically running services
    (
      let
        tor = nixosConfig.services.tor;

        userAgent = [ "-A" "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/97.0.4692.99 Safari/537.36" ];
        proxy = (lib.optionals (tor.enable && tor.client.enable) (
          let
            proxyProtocol = (if tor.client.dns.enable then "socks5h" else "socks5");
            proxyAddress = (if (builtins.substring 0 1 tor.client.socksListenAddress.addr) == "/" then
              "${tor.client.socksListenAddress.addr}:${toString tor.client.socksListenAddress.port}"
            else
              "localhost/${tor.client.socksListenAddress.addr}"
            );
          in
          [
            "-x"
            "${proxyProtocol}://${proxyAddress}"
          ]
        ));
      in
      pkgs.writeShellApplication {
        name = "autocurl";
        # name = "torcurl";
        # "that's a real toe-curler"

        runtimeInputs =
          [ pkgs.curl ]
          ++ lib.optional (nixosConfig.networking.networkmanager.enable) pkgs.networkmanager
        ;

        text = ''
          set -eu

          ${lib.optionalString nixosConfig.networking.networkmanager.enable "nm-online -t 60 || exit 7"}

          exec curl ${lib.escapeShellArgs [
            "--disable"
            "--silent"
            "--show-error"
            "--globoff"
            "--disallow-username-in-url"
            "--connect-timeout" 60
            "--max-time" 60
            "--retry" 10
            "--limit-rate" "512K"
            "--parallel"
            "--parallel-max" 4
            userAgent
            proxy
          ]}
        '';
      }
    )

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

{ config
, pkgs
, nixosConfig
, lib
, ...
}:
{
  imports = [
    ./commands
    ./editor
    ./git
    ./modules
    ./shell

    ./jq.nix
    ./less.nix
    ./man.nix
    ./monitor.nix
    ./pass.nix
    ./skim.nix
    ./spell.nix
    ./ssh.nix
    ./syncthing.nix
    ./tmux.nix
    ./xdg.nix
  ];

  persist = {
    allowOther = true;
    directories = [
      { method = "symlink"; directory = "bin"; }
    ];
  };

  cache = {
    allowOther = true;
    directories = [{ method = "symlink"; directory = "var/cache/nix"; }];
  };

  log = {
    allowOther = true;
    directories = [
      { method = "symlink"; directory = "logs"; }
    ];
  };

  home.keyboard.options = [ "compose:ralt" ];

  home.packages = [
    pkgs.curl
    pkgs.dateutils
    pkgs.execline
    pkgs.file
    pkgs.jdupes
    pkgs.lr
    pkgs.ltrace
    pkgs.moreutils
    pkgs.nq
    pkgs.outils
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

    # autocurl - curl for use by background/automatically running services
    (
      let
        inherit (nixosConfig.services) tor;

        userAgent = [ "-A" "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/97.0.4692.99 Safari/537.36" ];
        proxy = lib.optionals (tor.enable && tor.client.enable) (
          let
            proxyProtocol = if tor.client.dns.enable then "socks5h" else "socks5";
            proxyAddress =
              if (builtins.substring 0 1 tor.client.socksListenAddress.addr) == "/" then
                "${tor.client.socksListenAddress.addr}:${toString tor.client.socksListenAddress.port}"
              else
                "localhost/${tor.client.socksListenAddress.addr}";
          in
          [
            "-x"
            "${proxyProtocol}://${proxyAddress}"
          ]
        );
      in
      pkgs.writeShellApplication {
        name = "autocurl";
        # name = "torcurl";
        # "that's a real toe-curler"

        runtimeInputs =
          [ pkgs.curl ]
          ++ lib.optional nixosConfig.networking.networkmanager.enable pkgs.networkmanager
        ;

        text = ''
          ${lib.optionalString nixosConfig.networking.networkmanager.enable "nm-online -t 60 || exit 7"}
          exec curl \
              --disable \
              --silent \
              --show-error \
              --globoff \
              --disallow-username-in-url \
              --connect-timeout 60 \
              --max-time 60 \
              --retry 10 \
              --limit-rate 512K \
              --parallel \
              --parallel-max 4 \
              ${lib.escapeShellArgs [ userAgent proxy ]} "$@"
        '';
      }
    )
  ];

  systemd.user.startServices = true;

  home.sessionPath = [ "$HOME/bin" ];

  home.sessionVariables."SYSTEMD_PAGER" = "cat";

  home.stateVersion = "22.11";
}

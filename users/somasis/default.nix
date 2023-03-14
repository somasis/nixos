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

  home.persistence = {
    "/persist${config.home.homeDirectory}" = {
      directories = [
        { method = "symlink"; directory = "bin"; }
        { method = "symlink"; directory = "logs"; }
      ];

      allowOther = true;
    };

    "/cache${config.home.homeDirectory}" = {
      directories = [
        { method = "symlink"; directory = "var/cache/nix"; }
        { method = "symlink"; directory = "var/cache/nix-index"; }
      ];

      allowOther = true;
    };
  };

  home.keyboard.options = [ "compose:ralt" ];

  home.packages = [
    pkgs.dateutils
    pkgs.execline
    pkgs.extrace
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
    pkgs.uq
    pkgs.xe
    pkgs.xsv
    pkgs.xz
    pkgs.yq
    pkgs.zstd

    # autocurl - curl for use by background/automatically running services
    (
      let
        inherit (nixosConfig.services) tor;

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

  programs.jq.enable = true;

  systemd.user.startServices = true;

  home.sessionPath = [ "$HOME/bin" ];

  home.sessionVariables."SYSTEMD_PAGER" = "cat";

  programs.nix-index = {
    enable = true;
    enableBashIntegration = false;
  };

  home.stateVersion = "22.11";
}

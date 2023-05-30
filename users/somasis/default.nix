{ self
, config
, lib
, pkgs
, nixosConfig
, ...
}: {
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
    pkgs.limitcpu
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

        args = lib.cli.toGNUCommandLineShell { } ({
          disable = true;

          no-progress-meter = true;
          show-error = true;

          globoff = true;
          disallow-username-in-url = true;

          connect-timeout = 60;
          retry = 10;
          retry-delay = 5;

          limit-rate = "512K";
          compressed = true;

          parallel = true;
          parallel-max = 4;

          user-agent = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/97.0.4692.99 Safari/537.36";
        } // lib.optionalAttrs (tor.enable && tor.client.enable) {
          proxy = "${if tor.client.dns.enable then ''socks5h'' else ''socks5''}://${tor.client.socksListenAddress.addr}:${toString tor.client.socksListenAddress.port}";
        });
      in
      pkgs.writeShellApplication {
        name = "autocurl";

        runtimeInputs = [ pkgs.curl ]
          ++ lib.optional nixosConfig.networking.networkmanager.enable pkgs.networkmanager
        ;

        text = ''
          errors=0

          wait_online() {
              :
              ${lib.optionalString nixosConfig.networking.networkmanager.enable "nm-online -t 60 -q || return 7"}
          }

          check_err() {
              case "$1" in
                  5|6|7|35|45|55|56)
                      # network error of some sort, retry
                      errors=$(( errors + 1 ))
                      if [ "$errors" -gt 10 ]; then
                          printf 'error: failed to download %s times, refusing to continue waiting for network' "$errors" >&2
                          exit "$1"
                      fi

                      wait_online
                      ;;
                  0) exit 0 ;;
                  *) exit 1 ;;
              esac
          }

          e=5
          while check_err "$e"; do
              curl ${args} "$@" || e=$?
          done
        '';
      }
    )
  ];

  systemd.user.startServices = true;

  home.sessionPath = [ "$HOME/bin" ];

  home.sessionVariables."SYSTEMD_PAGER" = "cat";

  home.stateVersion = "22.11";
}

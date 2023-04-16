{ config, nixosConfig, lib, ... }:
let
  inherit (nixosConfig.services) tor;
in
{
  services.syncthing.enable = true;

  home.persistence."/persist${config.home.homeDirectory}".directories = [
    { method = "symlink"; directory = "etc/syncthing"; }
    { method = "symlink"; directory = "share/syncthing"; }
    { method = "symlink"; directory = "shared"; }
    { method = "symlink"; directory = "sync"; }
    { method = "symlink"; directory = "tracks"; }
  ];

  # Make syncthing more amicable to running while other programs are.
  systemd.user.services.syncthing = {
    Service = {
      Environment = [
        "GOMAXPROCS=1"
      ]
      # Use Tor to get around filters.
      ++ lib.optionals (tor.enable && tor.client.enable)
        [
          "all_proxy=socks5://${tor.client.socksListenAddress.addr}:${toString tor.client.socksListenAddress.port}"

          # Disabled because otherwise syncthing will try to use Tor
          # for accessing localhost (and thus, ssh tunneled connections)
          # "ALL_PROXY_NO_FALLBACK=1"
        ]
      ;

      Nice = 19;
      CPUSchedulingPolicy = "idle";
      # CPUSchedulingPriority = 15;
      IOSchedulingClass = "idle";
      IOSchedulingPriority = 7;
      OOMScoreAdjust = 1000;
      OOMPolicy = "continue";
    };
  };
}

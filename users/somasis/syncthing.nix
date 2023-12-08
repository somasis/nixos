{ config, osConfig, lib, ... }:
let
  inherit (osConfig.services) tor;
  inherit (lib.cli) toGNUCommandLineShell;
in
{
  services.syncthing = {
    enable = true;
    extraOptions = [ "--no-default-folder" ];
  };

  persist.directories = [
    { method = "symlink"; directory = config.lib.somasis.xdgConfigDir "syncthing"; }
    { method = "symlink"; directory = config.lib.somasis.xdgDataDir "syncthing"; }
    { method = "symlink"; directory = "shared"; }
    { method = "symlink"; directory = "sync"; }
    { method = "symlink"; directory = "tracks"; }
  ];

  systemd.user.services.syncthing = {
    # Unit.ConditionACPower = true;

    Service = {
      Environment = [ "GOMAXPROCS=1" ]
        # Use Tor to get around filters.
        ++ lib.optionals (tor.enable && tor.client.enable)
        [
          "all_proxy=socks5://${tor.client.socksListenAddress.addr}:${toString tor.client.socksListenAddress.port}"

          # Disabled because otherwise syncthing will try to use Tor
          # for accessing localhost (and thus, ssh tunneled connections)
          # "ALL_PROXY_NO_FALLBACK=1"
        ]
      ;

      # Make syncthing more amicable to running while other programs are.
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

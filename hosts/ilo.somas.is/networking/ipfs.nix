{ pkgs, ... }: {
  services.kubo = {
    enable = true;
    emptyRepo = true;

    startWhenNeeded = true;

    settings = {
      # Apply some of the settings from the "lowpower" profile
      AutoNAT.ServiceMode = "disabled";
      Reprovider.Interval = 0;

      Swarm.ConnMgr = {
        HighWater = 20;
        LowWater = 5;
        GracePeriod = "1m0s";
      };

      Datastore = {
        StorageMax = "2GB";
        GCPeriod = "24h";
      };
    };
  };

  systemd.services.ipfs.serviceConfig.stopWhenUnneeded = true;

  persist.directories = [{
    directory = "/var/lib/ipfs";
    user = "ipfs";
    group = "ipfs";
  }];
}

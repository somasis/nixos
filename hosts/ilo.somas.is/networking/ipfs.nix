{ pkgs, ... }: {
  services.kubo = {
    enable = true;
    enableGC = true;
    emptyRepo = true;

    startWhenNeeded = true;
  };
}

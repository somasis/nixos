{ pkgs
, lib
, inputs
, ...
}: {
  nix = {
    daemonCPUSchedPolicy = "idle";
    daemonIOSchedClass = "idle";

    settings = {
      trusted-users = [ "@wheel" ];
      max-jobs = 8;
      log-lines = 1000;

      auto-optimise-store = true;

      experimental-features = [ "ca-derivations" ];
      substituters = [ "https://cache.ngi0.nixos.org/" ];
      trusted-public-keys = [ "cache.ngi0.nixos.org-1:KqH5CBLNSyX184S9BKZJo1LxrxJ9ltnY2uAs5c/f1MA=" ];
    };

    gc = {
      automatic = true;
      dates = "monthly";
      options = "--delete-older-than 14d";
    };
  };

  # nixpkgs.config = {
  #   contentAddressedByDefault = true;
  # };
}

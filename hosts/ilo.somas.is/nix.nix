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

      connect-timeout = 5;

      auto-optimise-store = true;
      min-free = 1024000000; # 512 MB
      max-free = 1024000000; # 1 GB

      # Allow building from source if binary substitution fails
      fallback = true;

      # Quiet the dirty messages when using `nixos-dev`.
      warn-dirty = true;

      # TODO Use content-addressed derivations
      # <https://discourse.nixos.org/t/content-addressed-nix-call-for-testers/12881#:~:text=Level%203%20%E2%80%94%20Raider%20of%20the%20unknown>
      # experimental-features = [ "ca-derivations" ];
      # substituters = [ "https://cache.ngi0.nixos.org/" ];
      # trusted-public-keys = [ "cache.ngi0.nixos.org-1:KqH5CBLNSyX184S9BKZJo1LxrxJ9ltnY2uAs5c/f1MA=" ];
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

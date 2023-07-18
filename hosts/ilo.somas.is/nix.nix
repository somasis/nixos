{ config
, pkgs
, lib
, self
, nixpkgs
, ...
}:
# let
#   inherit (config.services.tor.client) socksListenAddress;
#   proxy = "socks5h://${socksListenAddress.addr}:${toString socksListenAddress.port}";
# in
{
  # systemd.services.nix-daemon.environment = lib.mkIf config.services.tor.client.enable {
  #   all_proxy = proxy;
  #   ftp_proxy = proxy;
  #   http_proxy = proxy;
  #   https_proxy = proxy;
  #   rsync_proxy = proxy;
  #   no_proxy = "127.0.0.1,localhost,.localdomain,192.168.0.0/16";
  # };

  nix = {
    daemonCPUSchedPolicy = "idle";
    daemonIOSchedClass = "idle";

    settings = {
      extra-experimental-features = [
        "flakes"
        "nix-command"

        "ca-derivations"

        "auto-allocate-uids"
      ];

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
      warn-dirty = false;

      builders-use-substitutes = true;

      substituters = [
        # Prefer HTTP nix-serve over the SSH tunnel to the server.
        # Faster for multiple missing-path queries.
        "http://localhost:5000"
        # "ssh-ng://nix-ssh@spinoza.7596ff.com"

        # Use binary cache for nonfree packages
        # <https://github.com/numtide/nixpkgs-unfree>
        "https://numtide.cachix.org"

        "https://nix-community.cachix.org"

        "https://cache.ngi0.nixos.org"
      ];

      trusted-public-keys = [
        "spinoza.7596ff.com-1:3evmjxB2owiKU1RcWMaVW7al/xdOG3QVqEEYwILPK1w="
        "numtide.cachix.org-1:2ps1kLBUWjxIneOy1Ik6cQjb41X0iXVXeHigGmycPPE="
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
        "cache.ngi0.nixos.org-1:KqH5CBLNSyX184S9BKZJo1LxrxJ9ltnY2uAs5c/f1MA="
      ];

      plugin-files = [ "${pkgs.nix-doc}/lib/libnix_doc_plugin.so" ];

      # TODO Use content-addressed derivations?
      # <https://discourse.nixos.org/t/content-addressed-nix-call-for-testers/12881#:~:text=Level%203%20%E2%80%94%20Raider%20of%20the%20unknown>
    };

    distributedBuilds = true;
    buildMachines = [{
      hostName = "spinoza.7596ff.com";

      system = "x86_64-linux";
      maxJobs = 4;

      protocol = "ssh";
      sshUser = "nix-ssh";
      sshKey = "${config.users.users.root.home}/.ssh/id_ed25519";

      publicHostKey = "c3NoLWVkMjU1MTkgQUFBQUMzTnphQzFsWkRJMU5URTVBQUFBSU5rSWRPNDVQeVozMDAydlRHbHN0cDJPMTV2cHo4akU2bXdjV1M2ZjZRUE4gcm9vdEBzcGlub3phCg==";

      supportedFeatures = [ "nixos-test" "benchmark" "big-parallel" "kvm" ];
    }];

    gc = {
      automatic = true;
      dates = "Sun 08:00:00";
      randomizedDelaySec = "1h";
      options = "--delete-older-than 7d";
    };

    registry = {
      nixpkgs.flake = nixpkgs;
      self.flake = self;
    };

    nixPath = [ "nixpkgs=flake:nixpkgs" ];
  };

  environment.systemPackages = [ pkgs.nix-doc ];

  programs.ssh.extraConfig = ''
    Host spinoza.7596ff.com
      ServerAliveInterval 15
      Compression yes
  '';

  programs.ssh.knownHosts.spinoza = {
    hostNames = [ "spinoza.7596ff.com" ];
    publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINkIdO45PyZ3002vTGlstp2O15vpz8jE6mwcWS6f6QPN";
  };
}

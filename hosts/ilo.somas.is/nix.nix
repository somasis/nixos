{ config
, pkgs
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
      warn-dirty = false;

      substituters = [ "ssh-ng://somasis@spinoza.7596ff.com" ];

      # TODO Use content-addressed derivations?
      # <https://discourse.nixos.org/t/content-addressed-nix-call-for-testers/12881#:~:text=Level%203%20%E2%80%94%20Raider%20of%20the%20unknown>
    };

    distributedBuilds = true;
    buildMachines = [{
      hostName = "spinoza.7596ff.com";
      sshUser = "somasis";
      sshKey = "${config.users.users.root.home}/.ssh/id_ed25519";
      system = "x86_64-linux";
      maxJobs = 4;

      publicHostKey = "c3NoLWVkMjU1MTkgQUFBQUMzTnphQzFsWkRJMU5URTVBQUFBSU5rSWRPNDVQeVozMDAydlRHbHN0cDJPMTV2cHo4akU2bXdjV1M2ZjZRUE4gcm9vdEBzcGlub3phCg==";

      protocol = "ssh-ng";
    }];

    gc = {
      automatic = true;
      dates = "monthly";
      options = "--delete-older-than 14d";
    };
  };

  programs.ssh.extraConfig = ''
    Host spinoza.7596ff.com
        PubkeyAcceptedKeyTypes ssh-ed25519

        Port 1312

        ControlMaster no
        ControlPath /tmp/%C.control.ssh
        ControlPersist 15m

        ServerAliveInterval 15

        Compression yes
  '';

  programs.ssh.knownHosts.spinoza = {
    hostNames = [ "spinoza.7596ff.com" ];
    publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINkIdO45PyZ3002vTGlstp2O15vpz8jE6mwcWS6f6QPN";
  };
}

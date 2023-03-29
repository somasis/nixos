{ pkgs, ... }: {
  security = {
    sudo.enable = false;
    doas = {
      enable = true;
      wheelNeedsPassword = false;

      extraRules = [{
        groups = [ "wheel" ];
        cmd = "${pkgs.nixos-rebuild}/bin/nixos-rebuild";
        noPass = true;
        keepEnv = true;
      }];
    };

    # Bring polkit's rules into harmony with doas.
    polkit.extraConfig = ''
      polkit.addRule(function(action, subject) {
          if (subject.isInGroup("wheel")) {
              return polkit.Result.YES;
          }
      });
    '';
  };

  # Always automatically recover from kernel panics by rebooting in 60 seconds
  boot.kernelParams = [ "panic=60" ];

  # programs.bash.interactiveShellInit = ''
  #   . ${pkgs.fetchurl {
  #     url = "https://raw.githubusercontent.com/Duncaen/OpenDoas/51f126a9a56cda5a291d5652b0685967133d7b90/doas.completion";
  #     hash = "sha256-SiByFXX4DOA1FKn7M7r/+3REsf7lfs1oJm/h0a2pdFI=";
  #   }}
  # '';
}

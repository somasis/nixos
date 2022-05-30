{ pkgs, ... }: {
  security = {
    sudo.enable = false;
    doas = {
      enable = true;
      wheelNeedsPassword = false;

      extraRules = [
        {
          groups = [ "wheel" ];
          cmd = "${pkgs.nixos-rebuild}/bin/nixos-rebuild";
          noPass = true;
          keepEnv = true;
        }
      ];
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
}

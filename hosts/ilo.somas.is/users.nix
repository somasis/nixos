{ config
, lib
, ...
}: {
  users = {
    mutableUsers = false;

    users = {
      # Disable root login.
      root.hashedPassword = "!";

      somasis = {
        isNormalUser = true;
        description = "Kylie McClain";
        uid = 1000;

        extraGroups =
          [ "systemd-journal" ]
          ++ lib.optional config.hardware.uinput.enable "input"
          ++ lib.optional config.security.sudo.enable "wheel"
          ++ lib.optional config.hardware.brillo.enable "video"
          ++ lib.optionals config.networking.networkmanager.enable [ "network" "networkmanager" ]
          ++ lib.optional config.hardware.sane.enable "scanner"
          ++ lib.optional config.services.printing.enable "lp"
          ++ lib.optional config.programs.adb.enable "adbusers"
        ;

        hashedPassword = "$y$j9T$TBHE4K4AUdpPQS6tXfWJJ.$bi.vigEvgXkq0G.gKZeKVvFX1m4hsiWNzI.SAZ2ConC";

        openssh.authorizedKeys.keys = [
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPkmjWLpicEaQOkM7FAv5bctmZjV5GjISYW7re0oknLU somasis@ilo.somas.is_20220603"
        ];
      };
    };
  };

  # IDEA: Synchronize user passwords with password store?
  # system.activationScripts.pass-users = {
  #   text = ''
  #     set -eu
  #     set -o pipefail

  #     for u in ${builtins.attrNames config.users.users}; do
  #         if p=$(pass "${config.networking.fqdnOrHostName}/users/$u" 2>&1); then
  #             printf '%s:%s\n' "$u" "$(tr -d '\n' <<< "$p" | mkpasswd -m sha-512 -s)"
  #         fi
  #     done
  #     # chpasswd -e
  #   '';
  # };

  persist.directories = [
    # Used for keeping declared users' UIDs and GIDs consistent across boots.
    { directory = "/var/lib/nixos"; user = "root"; group = "root"; mode = "0755"; }
  ];
}

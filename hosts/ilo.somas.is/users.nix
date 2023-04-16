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

        extraGroups = [
          # ./users/somasis/games/retroarch.nix: controller detection
          "input"
        ]
        ++ lib.optional config.security.doas.enable "wheel"
        ++ lib.optional config.hardware.brillo.enable "video"
        ++ lib.optionals config.networking.networkmanager.enable [ "network" "networkmanager" ]
        ++ lib.optional config.hardware.sane.enable "scanner"
        ++ lib.optional config.services.printing.enable "lp"
        ++ lib.optional config.programs.adb.enable "adbusers"
        ;

        hashedPassword = "$6$VfKdDqJkx4JrErSl$eJhjdLheyvqDO0hbWE87WKfr6q7qA6pvtmK.EnP.s5wPL7IBZOl1n6YFyrZdpG98HovE7D6X55B0.6c3NYj600";

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

  environment.persistence."/persist".directories = [
    # Used for keeping declared users' UIDs and GIDs consistent across boots.
    { directory = "/var/lib/nixos"; user = "root"; group = "root"; mode = "0755"; }
  ];
}

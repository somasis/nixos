{ config
, lib
, osConfig
, pkgs
, ...
}: {
  programs.git = {
    # Use SSH for signing commits, rather than GPG.
    extraConfig.gpg.format = "ssh";

    # Sign all commits and tags by default.
    signing.signByDefault = true;
    signing.key = "${config.xdg.configHome}/ssh/${config.home.username}@${osConfig.networking.fqdnOrHostName}:id_ed25519";

    # Store trusted signatures.
    extraConfig.gpg.ssh.allowedSignersFile = "${config.xdg.configHome}/ssh/allowed_signers";
  };
}

{ config, ... }: {
  programs.git = {
    # Use SSH for signing commits, rather than GPG.
    extraConfig.gpg.format = "ssh";

    # Sign all commits and tags by default.
    signing.signByDefault = true;

    signing.key = "${config.home.homeDirectory}/.ssh/id_ed25519";

    # Store trusted signatures.
    extraConfig.gpg.ssh.allowedSignersFile = "${config.home.homeDirectory}/.ssh/allowed_signers";
  };
}

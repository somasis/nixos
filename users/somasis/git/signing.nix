{ config, ... }: {
  programs.git = {
    # Use SSH for signing commits, rather than GPG.
    extraConfig.gpg.format = "ssh";

    # Sign all commits and tags by default.
    signing.signByDefault = true;

    extraConfig.gpg.ssh = {
      # Store trusted signatures.
      allowedSignersFile = "${config.xdg.configHome}/ssh/allowed_signers";

      defaultKeyCommand = builtins.toString (pkgs.writeShellScript "git-default-ssh-key" ''
        set -- ${lib.escapeShellArgs config.programs.ssh.matchBlocks."*".identityFile}

        for k; do
            [ -r "$k" ] && printf 'key::%s\n' "$k" && exit
        done
        exit 1
      '');
    };
  };
}

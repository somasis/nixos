{ config, ... }: {
  programs.git = {
    signing.key = "${config.home.homeDirectory}/.ssh/id_ed25519.pub";
    signing.signByDefault = true;
    extraConfig.gpg = {
      format = "ssh";
      ssh.allowedSignersFile = "${config.home.homeDirectory}/.ssh/trusted_signatures";
    };
  };
}

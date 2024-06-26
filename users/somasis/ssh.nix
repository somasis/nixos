{ config
, pkgs
, osConfig
, lib
, ...
}:
{
  persist.directories = [ "etc/ssh" ];
  cache.directories = [ (config.lib.somasis.xdgCacheDir "ssh") ];

  services.ssh-agent.enable = true;
  programs.ssh = {
    enable = true;

    compression = true;

    controlPersist = "5m";

    # HACK: I shouldn't have to put my UID here, right?
    controlPath = "/run/user/${toString osConfig.users.users.${config.home.username}.uid}/%C.control.ssh";
    userKnownHostsFile = "${config.xdg.cacheHome}/ssh/known_hosts";

    # Send an in-band keep-alive every 30 seconds.
    serverAliveInterval = 30;

    matchBlocks =
      let
        algorithmList = config.lib.somasis.commaList;
        appendAlgorithmList = x: "+" + algorithmList x;
        removeAlgorithmList = x: "-" + algorithmList x;
        prependAlgorithmList = x: "^" + algorithmList x;
      in
      {
        "*" = {
          identityFile = [
            "${config.xdg.configHome}/ssh/${config.home.username}@${osConfig.networking.fqdnOrHostName}:id_ed25519"
            "${config.xdg.configHome}/ssh/${config.home.username}@${osConfig.networking.fqdnOrHostName}:id_rsa"
            "${config.xdg.configHome}/ssh/id_ed25519"
            "${config.xdg.configHome}/ssh/id_rsa"
          ];

          # Too often, IPv6 is broken on the wifi I'm on.
          addressFamily = "inet";

          # Use my local language and timezone whenever possible.
          sendEnv = [ "LANG" "LANGUAGE" "TZ" ];

          extraOptions = {
            # Can be spoofed, and dies over short connection route failures
            TCPKeepAlive = "no";

            # Accept unknown keys for unfamiliar hosts, yell when known hosts change their key.
            StrictHostKeyChecking = "accept-new";

            CASignatureAlgorithms = appendAlgorithmList [ "rsa-sha2-256" "rsa-sha2-512" ];

            HostKeyAlgorithms = prependAlgorithmList [
              "ssh-ed25519-cert-v01@openssh.com"
              "sk-ssh-ed25519-cert-v01@openssh.com"
              "ssh-ed25519"
              "sk-ssh-ed25519@openssh.com"
            ];

            KexAlgorithms = removeAlgorithmList [
              "ecdh-sha2-nistp256"
              "ecdh-sha2-nistp384"
              "ecdh-sha2-nistp521"
              "diffie-hellman-group14-sha256"
            ];

            MACs = removeAlgorithmList [
              "umac-64-etm@openssh.com"
              "hmac-sha1-etm@openssh.com"
              "umac-64@openssh.com"
              "umac-128@openssh.com"
              "hmac-sha2-256"
              "hmac-sha2-512"
              "hmac-sha1"
            ];

            PubkeyAcceptedAlgorithms = prependAlgorithmList [
              "ssh-ed25519-cert-v01@openssh.com"
              "sk-ssh-ed25519-cert-v01@openssh.com"
              "ssh-ed25519"
              "sk-ssh-ed25519@openssh.com"
            ];
          };
        };

        "strauss.exherbo.org" = {
          host = "strauss.exherbo.org git.exherbo.org exherbo.org git.e.o";
          hostname = "strauss.exherbo.org";
          user = "git";
        };

        "git.causal.agency" = {
          identityFile = "${config.xdg.configHome}/ssh/${config.home.username}@trotsky.somas.is:id_ed25519";
          port = 2222;
        };

        # Use GitHub SSH over the HTTPS port, to trick firewalls.
        # <https://help.github.com/articles/using-ssh-over-the-https-port/>
        "github.com" = {
          hostname = "ssh.github.com";
          user = "git";
          port = 443;
        };

        # Use GitLab.com SSH over the HTTPS port, to trick firewalls.
        # <https://docs.gitlab.com/ee/user/gitlab_com/#alternative-ssh-port>
        "gitlab.com" = {
          hostname = "altssh.gitlab.com";
          user = "git";
          port = 443;
        };

        # Frequent hosts
        "lacan.somas.is" = {
          host = "lacan.somas.is lacan";
          hostname = "lacan.somas.is";

          forwardAgent = true;
          dynamicForwards = [{ address = "localhost"; port = 6003; }];
        };

        "spinoza.7596ff.com" = {
          host = "spinoza.7596ff.com spinoza";
          hostname = "spinoza.7596ff.com";

          forwardAgent = true;
          forwardX11 = true;
        };

        "genesis.whatbox.ca" = {
          host = "genesis.whatbox.ca whatbox genesis";
          hostname = "genesis.whatbox.ca";
        };
      };
  };

  home.packages = [ pkgs.mosh ];
  home.sessionVariables."MOSH_TITLE_NOPREFIX" = 1; # Disable prepending "[mosh]" to terminal title
}

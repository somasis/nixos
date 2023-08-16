{ config
, pkgs
, osConfig
, lib
, ...
}: {
  persist.directories = [ "etc/ssh" ];
  cache.directories = [ "var/cache/ssh" ];

  programs.ssh = {
    enable = true;

    compression = true;

    controlPersist = "5m";

    # HACK: I shouldn't have to put my UID here, right?
    controlPath = "/run/user/${toString osConfig.users.users.${config.home.username}.uid}/%C.control.ssh";
    userKnownHostsFile = "${config.xdg.cacheHome}/ssh/known_hosts";

    # Send an in-band keep-alive every 30 seconds.
    serverAliveInterval = 30;

    matchBlocks = let algoList = lib.concatStringsSep ","; in {
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

          HostKeyAlgorithms = algoList [
            "ssh-ed25519-cert-v01@openssh.com"
            "sk-ssh-ed25519-cert-v01@openssh.com"
            "ssh-ed25519"
            "sk-ssh-ed25519@openssh.com"
          ];

          PubkeyAcceptedAlgorithms = algoList [
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

  services.ssh-agent.enable = true;

  home.packages = [ pkgs.mosh ];
  home.sessionVariables."MOSH_TITLE_NOPREFIX" = 1; # Disable prepending "[mosh]" to terminal title
}

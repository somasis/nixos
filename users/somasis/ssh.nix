{ config
, pkgs
, nixosConfig
, ...
}: {
  home.persistence."/persist${config.home.homeDirectory}".directories = [ ".ssh" ];
  home.persistence."/cache${config.home.homeDirectory}".directories = [ "var/cache/ssh" ];

  programs.ssh = {
    enable = true;

    # compression = true;
    hashKnownHosts = true;
    userKnownHostsFile = "${config.xdg.cacheHome}/ssh/known_hosts";

    controlPersist = "5m";

    # HACK: I shouldn't have to put my UID here, right?
    controlPath = "/run/user/${toString nixosConfig.users.users.${config.home.username}.uid}/%C.control.ssh";

    # Send an in-band keep-alive every 30 seconds.
    serverAliveInterval = 30;

    matchBlocks = {
      "*" = {
        # Too often, IPv6 is broken on the wifi I'm on.
        addressFamily = "inet";

        # Use my local language and timezone whenever possible.
        sendEnv = [ "LANG" "LANGUAGE" "TZ" ];

        extraOptions = {
          # Can be spoofed, and dies over short connection route failures
          "TCPKeepAlive" = "no";

          # Accept unknown keys for unfamiliar hosts, yell when known hosts change their key.
          "StrictHostKeyChecking" = "accept-new";
        };
      };

      "strauss.exherbo.org" = {
        host = "strauss.exherbo.org git.exherbo.org exherbo.org git.e.o";
        hostname = "strauss.exherbo.org";
        user = "git";
      };

      "git.causal.agency".port = 2222;

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

      "trotsky.somas.is" = {
        host = "trotsky.somas.is trotsky";
        hostname = "trotsky.somas.is";
        port = 5398;

        forwardAgent = true;
        forwardX11 = true;
      };

      "spinoza.7596ff.com" = {
        host = "spinoza.7596ff.com spinoza";
        hostname = "spinoza.7596ff.com";
        port = 1312;

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
}

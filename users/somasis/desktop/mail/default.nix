{ config
, pkgs
, lib
, nixosConfig
, ...
}:
let
  offlineimapNametransGmail = {
    remote.nametrans = "lambda f: f.replace('[Gmail]/', '') if f.startswith('[Gmail]/') else f";
    local.nametrans = "lambda f: '[Gmail]/' + f if f in ['Drafts', 'Starred', 'Important', 'Spam', 'Trash', 'All Mail', 'Sent Mail'] else f";
  };

  systemdName = lib.replaceChars [ "@" ":" "\\" "[" "]" ] [ "-" "-" "-" "" "" ];

  passCmd = "${config.programs.password-store.package}/bin/pass";
  systemctl = "${pkgs.systemd}/bin/systemctl --user";
in
{
  imports = [
    ./mblaze.nix
  ];

  accounts.email.maildirBasePath = "mail";

  home.persistence."/persist${config.home.homeDirectory}".directories = [
    "share/offlineimap"

    "mail/sms"
  ]
  ++ builtins.map
    (x: {
      directory = "mail/${x.maildir.path}";
      method = "symlink";
    })
    (builtins.attrValues config.accounts.email.accounts)
  ;

  accounts.email.accounts =
    let
      realName = "Kylie McClain";
    in
    {
      "kylie@somas.is" = { name, ... }: rec {
        address = name;
        passwordCommand = "${passCmd} show ${nixosConfig.networking.fqdn}/nixos/${address}";

        inherit realName;

        primary = true;

        aliases = [
          "kylie@fastmail.com"
          "abuse@somas.is"
          "somasis@somas.is"
          "me@somas.is"
        ];

        flavor = "fastmail.com";

        offlineimap.enable = true;
        imapnotify = rec {
          enable = true;
          onNotify = "${systemctl} start offlineimap-${systemdName name}.service";
          boxes = [ "INBOX" ];
        };
        msmtp.enable = true;
      };

      "mcclainkj@appstate.edu" = { name, ... }: {
        inherit realName;
        address = name;
        passwordCommand = "${passCmd} show www/appstate.edu/mcclainkj";

        aliases = [ "mcclainhj@appstate.edu" ];

        flavor = "gmail.com";

        offlineimap.enable = true;
        offlineimap.extraConfig = offlineimapNametransGmail;
        imapnotify = rec {
          enable = true;
          onNotify = "${systemctl} start offlineimap-${systemdName name}.service";
          boxes = [ "INBOX" ];
        };
        msmtp.enable = true;
      };

      "somasissounds@gmail.com" = { name, ... }: rec {
        address = name;
        passwordCommand = "${passCmd} show ${nixosConfig.networking.fqdn}/nixos/${address}";

        inherit realName;

        flavor = "gmail.com";

        offlineimap.enable = true;
        offlineimap.extraConfig = offlineimapNametransGmail;
        imapnotify = rec {
          enable = true;
          onNotify = "${systemctl} start offlineimap-${systemdName name}.service";
          boxes = [ "INBOX" ];
        };
        msmtp.enable = true;
      };
    };

  programs.offlineimap.enable = true;
  programs.msmtp.enable = true;

  systemd.user = {
    targets.mail = {
      Unit.Description = "All mail management services";
      Install.WantedBy = [ "default.target" ];
    };
  }
  // lib.foldr
    (n: a:
      lib.recursiveUpdate a {
        services."offlineimap-${systemdName n}" = {
          Unit.Description = "Synchronize IMAP boxes for account ${n}";
          Service = {
            Type = "oneshot";

            ExecStartPre = [ "${pkgs.networkmanager}/bin/nm-online -q" ];
            ExecStart = [ "${pkgs.torsocks}/bin/torsocks ${pkgs.offlineimap}/bin/offlineimap -o -u syslog -a ${n}" ];

            SyslogIdentifier = "offlineimap";

            Nice = 19;
            CPUSchedulingPolicy = "idle";
            IOSchedulingClass = "idle";
            IOSchedulingPriority = 7;
          };
        };

        timers."offlineimap-${systemdName n}" = {
          Unit.Description = "Synchronize IMAP boxes for account ${n} every hour and fifteen minutes after startup";
          Timer = {
            OnCalendar = "hourly";
            OnStartupSec = "900";
            Persistent = true;
            AccuracySec = "5m";
            RandomizedDelaySec = "1m";
          };

          Unit.PartOf = [ "timers.target" "mail.target" ];
          Install.WantedBy = [ "timers.target" "mail.target" ];
        };

        paths."offlineimap-${systemdName n}" = {
          Unit.Description = "Synchronize IMAP boxes on local changes";
          Path.PathChanged = config.accounts.email.accounts."${n}".maildir.absPath;

          Unit.PartOf = [ "paths.target" "mail.target" ];
          Install.WantedBy = [ "paths.target" "mail.target" ];
        };
      })
    { }
    (builtins.attrNames config.accounts.email.accounts)
  ;

  services.imapnotify.enable = true;

  home.packages = [ pkgs.mail-deduplicate ];
}

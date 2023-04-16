{ config
, pkgs
, lib
, nixosConfig
, ...
}:
let
  # inherit (lib) systemdName;
  systemdName = lib.replaceStrings [ "@" ":" "\\" "[" "]" ] [ "-" "-" "-" "" "" ];

  offlineimapNametransGmail = {
    remote.nametrans = "lambda f: f.replace('[Gmail]/', '') if f.startswith('[Gmail]/') else f";
    local.nametrans = "lambda f: '[Gmail]/' + f if f in ['Drafts', 'Starred', 'Important', 'Spam', 'Trash', 'All Mail', 'Sent Mail'] else f";
  };

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
    (x: { method = "symlink"; directory = "mail/${x.maildir.path}"; })
    (builtins.attrValues config.accounts.email.accounts)
  ;

  accounts.email.accounts =
    let
      realName = "Kylie McClain";
    in
    {
      "kylie@somas.is" = { name, ... }: rec {
        address = name;
        passwordCommand = "${passCmd} show ${nixosConfig.networking.fqdnOrHostName}/nixos/${address}";

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
        passwordCommand = "${passCmd} show ${nixosConfig.networking.fqdnOrHostName}/nixos/${address}";

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

  systemd.user = lib.foldr
    (n: a:
      lib.recursiveUpdate a {
        services."offlineimap-${systemdName n}" = {
          Unit.Description = "Synchronize IMAP boxes for account ${n}";
          Service = {
            Type = "oneshot";

            ExecStart = [ "${pkgs.limitcpu}/bin/cpulimit -qf -l 25 -- ${lib.optionalString nixosConfig.services.tor.client.enable "${pkgs.torsocks}/bin/torsocks"} ${pkgs.offlineimap}/bin/offlineimap -o -u syslog -a ${n}" ];

            SyslogIdentifier = "offlineimap";

            Nice = 19;
            CPUSchedulingPolicy = "idle";
            IOSchedulingClass = "idle";
            IOSchedulingPriority = 7;
          } // (lib.optionalAttrs nixosConfig.networking.networkmanager.enable { ExecStartPre = [ "${pkgs.networkmanager}/bin/nm-online -q" ]; });
        };

        timers."offlineimap-${systemdName n}" = {
          Unit.Description = "Synchronize IMAP boxes for account ${n} every two hours, and fifteen minutes after startup";
          Timer = {
            OnCalendar = "1/2:00:00";
            OnStartupSec = builtins.toString (60 * 15);
            Persistent = true;
            RandomizedDelaySec = "1m";
          };

          Unit.PartOf = [ "mail.target" ];
          Install.WantedBy = [ "mail.target" ];
        };

        paths."offlineimap-${systemdName n}" = {
          Unit.Description = "Synchronize IMAP boxes on local changes";
          Path.PathChanged = config.accounts.email.accounts."${n}".maildir.absPath;

          Unit.PartOf = [ "mail.target" ];
          Install.WantedBy = [ "mail.target" ];
        };

        services."imapnotify-${systemdName n}" = {
          Unit.PartOf = [ "mail.target" ];
          Install.WantedBy = [ "mail.target" ];
        };
      })
    {
      targets.mail = {
        Unit = {
          Description = "All mail management services";
          PartOf = [ "default.target" ];
        };

        Install.WantedBy = [ "default.target" ];
      };
    }
    (builtins.attrNames config.accounts.email.accounts)
  ;

  services.imapnotify.enable = true;

  # xdg.configFile."tmux/mtui.conf".text = ''
  #   source "$XDG_CONFIG_HOME/tmux/unobtrusive.conf"

  #   set-option -g set-titles-string "mtui - #T"
  #   set-option -g window-status-format          " #I #W "
  #   set-option -g window-status-current-format  " #I #W "

  #   set-option -g remain-on-exit on

  #   # Binds.
  #   bind-key -n C-q kill-server

  #   set-option -g status-right ""
  #   # set-option -g history-limit 10000

  #   # set-hook -t 0.0 pane-exited "kill-session -t mtui"
  # '';

  # home.packages = [ pkgs.mail-deduplicate ];
}

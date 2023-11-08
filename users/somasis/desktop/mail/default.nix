{ config
, pkgs
, lib
, osConfig
, ...
}:
let
  inherit (lib) getBin foldr recursiveUpdate optionalAttrs;
  inherit (config.lib.somasis) mkPathSafeName;

  offlineimapNametransGmail = {
    remote.nametrans = "lambda f: f.replace('[Gmail]/', '') if f.startswith('[Gmail]/') else f";
    local.nametrans = "lambda f: '[Gmail]/' + f if f in ['Drafts', 'Starred', 'Important', 'Spam', 'Trash', 'All Mail', 'Sent Mail'] else f";
  };

  pass = "${getBin config.programs.password-store.package}/bin/pass";
  systemctl = "${pkgs.systemd}/bin/systemctl --user";
in
{
  imports = [ ./mblaze.nix ];

  accounts.email.maildirBasePath = "mail";

  persist.directories = [
    { method = "symlink"; directory = "share/offlineimap"; }
    { method = "symlink"; directory = "mail/sms"; }
  ]
  ++ map
    (x: { method = "symlink"; directory = "mail/${x.maildir.path}"; })
    (builtins.attrValues config.accounts.email.accounts)
  ;

  accounts.email.accounts =
    let
      account = address: extraAttrs:
        lib.recursiveUpdate
          {
            "${address}" = let acc = config.accounts.email.accounts."${address}"; in {
              inherit address;

              realName = "Kylie McClain";
              passwordCommand = "${pass} show ${osConfig.networking.fqdnOrHostName}/nixos/${address}";

              folders.inbox = "INBOX";

              offlineimap.enable = true;

              imapnotify = {
                enable = true;
                onNotify = "offlineimap -a ${address} -u syslog";
                boxes = [ "INBOX" ];
              };

              msmtp.enable = true;
            };
          }
          { "${address}" = extraAttrs; }
      ;
    in
    lib.mkMerge [
      (account "kylie@somas.is" {
        primary = true;

        aliases = [
          "kylie@fastmail.com"
          "abuse@somas.is"
          "somasis@somas.is"
          "me@somas.is"
          "somasissounds@gmail.com"
          "dieselmcclain@gmail.com"
        ];

        flavor = "fastmail.com";
      })

      (account "mcclainkj@appstate.edu" {
        passwordCommand = "${pass} show www/appstate.edu/mcclainkj";
        aliases = [ "mcclainhj@appstate.edu" ];

        flavor = "gmail.com";
        folders.sent = "Sent Mail";

        offlineimap.extraConfig = offlineimapNametransGmail;
      })
    ]
  ;

  programs.offlineimap.enable = true;
  programs.msmtp.enable = true;

  services.imapnotify.enable = true;

  # systemd.user = foldr
  #   (n: a:
  #     recursiveUpdate a {
  #       services."offlineimap-${mkPathSafeName n}" = {
  #         Unit.Description = "Synchronize IMAP boxes for account ${n}";
  #         Service = {
  #           Type = "oneshot";

  #           ExecStart = [ "${pkgs.limitcpu}/bin/cpulimit -qf -l 25 -- ${pkgs.offlineimap}/bin/offlineimap -o -u quiet -a ${n}" ];

  #           SyslogIdentifier = "offlineimap";

  #           Nice = 19;
  #           CPUSchedulingPolicy = "idle";
  #           IOSchedulingClass = "idle";
  #           IOSchedulingPriority = 7;
  #         } // (optionalAttrs osConfig.networking.networkmanager.enable { ExecStartPre = [ "${pkgs.networkmanager}/bin/nm-online -q" ]; });
  #       };

  #       timers."offlineimap-${mkPathSafeName n}" = {
  #         Unit.Description = "Synchronize IMAP boxes for account ${n} every two hours, and fifteen minutes after startup";
  #         Timer = {
  #           OnCalendar = "1/2:00:00";
  #           OnStartupSec = 60 * 15;
  #           Persistent = true;
  #           RandomizedDelaySec = "1m";
  #         };

  #         Unit.PartOf = [ "mail.target" ];
  #         Install.WantedBy = [ "mail.target" ];
  #       };

  #       paths."offlineimap-${mkPathSafeName n}" = {
  #         Unit.Description = "Synchronize IMAP boxes on local changes";
  #         Path.PathChanged = config.accounts.email.accounts."${n}".maildir.absPath;

  #         Unit.PartOf = [ "mail.target" ];
  #         Install.WantedBy = [ "mail.target" ];
  #       };

  #       services."imapnotify-${mkPathSafeName n}" = {
  #         Unit.PartOf = [ "mail.target" ];
  #         Install.WantedBy = [ "mail.target" ];
  #       };
  #     })
  #   {
  #     targets.mail = {
  #       Unit = {
  #         Description = "All mail management services";
  #         PartOf = [ "default.target" ];
  #       };

  #       Install.WantedBy = [ "default.target" ];
  #     };
  #   }
  #   (builtins.attrNames config.accounts.email.accounts)
  # ;

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
}

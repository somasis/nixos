{ config
, pkgs
, lib
, osConfig
, ...
}:
let
  xdgRuntimeDir = "/run/user/${toString osConfig.users.users.${config.home.username}.uid}";

  secret-mpdscribble = pkgs.writeShellApplication {
    name = "secret-mpdscribble";
    runtimeInputs = [ config.programs.password-store.package ];

    text = ''
      cat <<EOF
      ${mpdscribbleConf}
      EOF
    '';
  };

  # INI is shell-expanded as a heredoc, so be careful with special characters
  mpdscribbleConf = lib.generators.toINIWithGlobalSection { } {
    globalSection = {
      log = "-";
      host = config.services.mpd.network.listenAddress;
      port = builtins.toString config.services.mpd.network.port;
      verbose = 1;
    };

    sections."last.fm" = {
      journal = "${config.xdg.cacheHome}/mpdscribble/last.fm.journal";
      url = "https://post.audioscrobbler.com/";

      username = "kyliesomasis";
      password = "$(pass www/last.fm/kyliesomasis | tr -d '\n' | md5sum - | cut -d' ' -f1)";
    };
  };

  mpdscribble = pkgs.wrapCommand {
    package = pkgs.mpdscribble;

    wrappers = [{
      command = "/bin/mpdscribble";
      prependFlags = ''--conf <(${secret-mpdscribble}/bin/secret-mpdscribble)'';
    }];
  };
in
{
  cache = {
    directories = [{
      method = "symlink";
      directory = config.lib.somasis.xdgCacheDir "mpdscribble";
    }];

    files = [ (config.lib.somasis.xdgDataDir "listenbrainz-mpd-cache.sqlite3") ];
  };

  home.packages = [ mpdscribble ];

  services.listenbrainz-mpd = {
    enable = true;
    settings = {
      submission.token_file = "${xdgRuntimeDir}/listenbrainz-mpd.secret";
      mpd.address = "${config.services.mpd.network.listenAddress}:${builtins.toString config.services.mpd.network.port}";

      # Doesn't seem to honor this configuration variable...?
      # submission.cache_file = "${config.xdg.cacheHome}/listenbrainz-mpd/cache.sqlite3";
    };
  };

  systemd.user.services = {
    listenbrainz-mpd = {
      Unit.After = [ "mpd.service" ];
      Unit.BindsTo = [ "mpd.service" ];
      Install.WantedBy = [ "mpd.service" ];

      Service = {
        Environment = [ "TOKEN_ENTRY=www/listenbrainz.org" ];
        ExecStartPre = pkgs.writeShellScript "listenbrainz-mpd-secret" ''
          PATH=${lib.makeBinPath [ config.programs.password-store.package pkgs.coreutils ]}:"$PATH"
          : "''${XDG_RUNTIME_DIR:?}"
          : "''${TOKEN_ENTRY:?}"
          umask 0077
          pass show "$TOKEN_ENTRY" | head -n1 > "$XDG_RUNTIME_DIR/listenbrainz-mpd.secret"
        '';
        ExecStopPost = [ "${pkgs.coreutils}/bin/rm -f %t/listenbrainz-mpd.secret" ];
      };
    };

    mpdscribble = {
      Unit = {
        Description = pkgs.mpdscribble.meta.description;
        BindsTo = [ "mpd.service" ];
        After = [ "mpd.service" ];
      };
      Install.WantedBy = [ "mpd.service" ];

      Service = {
        Type = "simple";
        ExecStart = [ "${mpdscribble}/bin/mpdscribble -D" ];
      };
    };
  };
}

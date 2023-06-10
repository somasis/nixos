{ config
, pkgs
, lib
, ...
}:
let
  xdgRuntimeDir = "/run/user/${toString nixosConfig.users.users.${config.home.username}.uid}";

  mpdscribble = pkgs.symlinkJoin {
    name = "mpdscribble";
    paths = [ pkgs.mpdscribble pass-mpdscribble ];
    buildInputs = [ pkgs.makeWrapper ];
    postBuild = ''
      wrapProgram $out/bin/mpdscribble \
          --add-flags '--conf <(pass-mpdscribble)'
    '';
  };

  pass-mpdscribble = pkgs.writeShellApplication {
    name = "pass-mpdscribble";
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
in
{
  cache.directories = [
    { method = "symlink"; directory = "var/cache/listenbrainz-mpd"; }
    { method = "symlink"; directory = "var/cache/mpdscribble"; }
  ];

  home.packges = [ mpdscribble ];

  services.listenbrainz-mpd = {
    enable = true;
    settings = {
      submission.token_file = "${xdgRuntimeDir}/listenbrainz-mpd.secret";
      submission.cache_file = "${config.xdg.cacheHome}/listenbrainz-mpd/cache.sqlite3";
      mpd.address = "${config.services.mpd.network.listenAddress}:${builtins.toString config.services.mpd.network.port}";
    };
  };

  systemd.user.services = {
    listenbrainz-mpd = {
      Unit.After = [ "mpd.service" ];
      Unit.BindsTo = [ "mpd.service" ];
      Install.WantedBy = [ "mpd.service" ];

      Service.Environment = [
        "ENTRY=${nixosConfig.networking.fqdnOrHostName}/listenbrainz-mpd"
        "PATH=${lib.getBin config.programs.password-store.package}/bin"
      ];

      Service.ExecStartPre = pkgs.writeShellScript "listenbrainz-mpd-secret" ''
        : ''${XDG_RUNTIME_DIR:?}
        umask 0077
        exec pass "$ENTRY" > "$XDG_RUNTIME_DIR/listenbrainz-mpd.secret"
      '';
      Service.ExecStopPre = [ "${pkgs.coreutils}/bin/rm -f %t/listenbrainz-mpd.secret" ];
    };

    mpdscribble = {
      Unit.Description = pkgs.mpdscribble.meta.description;
      Unit.BindsTo = [ "mpd.service" ];
      Unit.After = [ "mpd.service" ];
      Install.WantedBy = [ "mpd.service" ];

      Service = {
        Type = "simple";
        ExecStart = [ "${mpdscribble}/bin/mpdscribble -D" ];
      };
    };
  };
}

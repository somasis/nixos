{ nixosConfig
, lib
, pkgs
, config
, ...
}:
let
  xdgRuntimeDir = "/run/user/${toString nixosConfig.users.users.${config.home.username}.uid}";

  pass-mpdscribble = pkgs.writeShellApplication {
    name = "pass-mpdscribble";
    runtimeInputs = [
      config.programs.password-store.package
    ];

    text = ''
      cat <<EOF
      log = -
      host = ${xdgRuntimeDir}/mpd/socket
      verbose = 2

      [last.fm]
      url = https://post.audioscrobbler.com/
      username = kyliesomasis
      password = $(pass www/last.fm/kyliesomasis | tr -d '\n' | md5sum - | cut -d' ' -f1)
      journal = ${config.xdg.cacheHome}/mpdscribble/last.fm.journal

      [listenbrainz]
      url = http://proxy.listenbrainz.org
      username = Somasis
      password = $(pass ${nixosConfig.networking.fqdn}/mpdscribble/listenbrainz.org)
      journal = ${config.xdg.cacheHome}/mpdscribble/listenbrainz.journal
      EOF
    '';
  };

  mpdscribble = pkgs.symlinkJoin {
    name = "mpdscribble";
    paths = [ pkgs.mpdscribble pass-mpdscribble ];
    buildInputs = [ pkgs.makeWrapper ];
    postBuild = ''
      wrapProgram $out/bin/mpdscribble \
          --add-flags '--conf <(pass-mpdscribble)'
    '';
  };
in
{
  xdg.userDirs.music = "${config.home.homeDirectory}/audio/library";

  services.mpd = {
    enable = true;

    network.listenAddress = "${xdgRuntimeDir}/mpd/socket";

    musicDirectory = "${config.xdg.userDirs.music}/lossy";
    playlistDirectory = "${config.xdg.userDirs.music}/playlists";
  };

  home.persistence = {
    "/cache${config.home.homeDirectory}".directories = [ "var/cache/mpdscribble" ];
    "/persist${config.home.homeDirectory}".directories = [ "share/mpd" ];
  };

  home.sessionVariables.MPD_HOST = config.services.mpd.network.listenAddress;

  home.packages = [ mpdscribble ];

  systemd.user.services.mpdscribble = {
    Unit = {
      Description = pkgs.mpdscribble.meta.description;
      PartOf = [ "default.target" ];
      After = [ "mpd.service" ];
    };
    Install.WantedBy = [ "default.target" "mpd.service" ];

    Service = {
      Type = "simple";
      ExecStart = [ "${mpdscribble}/bin/mpdscribble -D" ];
    };
  };

  services.mpdris2 = {
    enable = config.services.mpd.enable;
    mpd = {
      host = config.services.mpd.network.listenAddress;
      musicDirectory = config.services.mpd.musicDirectory;
    };
  };

  services.sxhkd.keybindings =
    let
      mpc-toggle = pkgs.writeShellScript "mpc-toggle" ''
        c=$(${pkgs.mpc-cli}/bin/mpc playlist | wc -l)
        [ "$c" -gt 0 ] || ${pkgs.mpc-cli}/bin/mpc add /
        ${pkgs.mpc-cli}/bin/mpc toggle
      '';
    in
    {
      # Music: {play/pause, stop, previous track, next track}
      "XF86AudioPlay" = "${mpc-toggle}";
      "XF86AudioStop" = "${pkgs.mpc-cli}/bin/mpc stop";
      "XF86AudioPrev" = "${pkgs.mpc-cli}/bin/mpc cdprev";
      "XF86AudioNext" = "${pkgs.mpc-cli}/bin/mpc next";

      # Music: toggle {consume, random} mode
      "super + XF86Audio{Prev,Play}" = "${pkgs.mpc-cli}/bin/mpc {consume,random}";
    };
}

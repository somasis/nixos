{ nixosConfig
, music
, pkgs
, config
, ...
}:
let
  xdgRuntimeDir = "/run/user/${toString nixosConfig.users.users.${config.home.username}.uid}";
in
{
  services.mpd = {
    enable = true;

    musicDirectory = music.lossy;
    network.listenAddress = "${xdgRuntimeDir}/mpd/socket";

    playlistDirectory = "${music.lossy}/_playlists";
  };

  home.sessionVariables.MPD_HOST = config.services.mpd.network.listenAddress;

  home.packages = [ pkgs.mpris-scrobbler ];

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

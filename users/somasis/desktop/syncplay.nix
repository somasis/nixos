{ pkgs
, lib
, config
, ...
}:
with lib.generators;
let
  mkList = list: "[" + (lib.concatStringsSep "," (map (x: ''"${x}"'') list)) + "]";

  mpv = "${config.programs.mpv.package}/bin/mpv";

  syncplayINI = toINI { } {
    general.checkforupdatesautomatically = false;

    client_settings = {
      name = "${config.home.username}";
      playerpath = mpv;

      # time synchronization
      dontslowdownwithme = false;
      fastforwardondesync = true;
      fastforwardthreshold = 5.0;
      rewindondesync = true;
      rewindthreshold = 4.0;
      slowdownthreshold = 1.5;
      slowondesync = true;

      # playback
      pauseonleave = true;
      unpauseaction = "IfOthersReady";

      # playlist
      sharedplaylistenabled = true;
      readyatstart = true;

      autoplayminusers = -1.0;
      autoplayrequiresamefilenames = true;

      filenameprivacymode = "SendRaw";
      filesizeprivacymode = "SendRaw";
      loopatendofplaylist = false;
      loopsinglefiles = false;

      onlyswitchtotrusteddomains = true;
      trusteddomains = mkList [
        "drive.google.com"
        "instagram.com"
        "vimeo.com"
        "tumblr.com"
        "twitter.com"
        "youtube.com"
        "youtu.be"
      ];

      mediasearchdirectories = mkList [
        "${config.xdg.userDirs.download}"
        "${config.home.homeDirectory}/mess/current"
        "${config.xdg.userDirs.videos}/film"
        "${config.xdg.userDirs.videos}/tv"
        "${config.home.homeDirectory}/mnt/sftp/genesis.whatbox.ca/files/video/film"
        "${config.home.homeDirectory}/mnt/sftp/genesis.whatbox.ca/files/video/tv"
      ];

      room = "anime";
      roomlist = mkList [
        "anime"
        "pones"
        "wives"
      ];
    };

    client_settings.forceguiprompt = true;
    gui = {
      alerttimeout = 5.0;
      chatbottommargin = 30.0;
      chatdirectinput = true;
      chatinputenabled = true;
      chatinputfontcolor = "#ffff00";
      chatinputfontfamily = "monospace";
      chatinputfontunderline = false;
      chatinputfontweight = 50.0;
      chatinputposition = "Top";
      chatinputrelativefontsize = 24.0;
      chatleftmargin = 20.0;
      chatmaxlines = 7.0;
      chatmoveosd = true;
      chatosdmargin = 110.0;
      chatoutputenabled = true;
      chatoutputfontfamily = "monospace";
      chatoutputfontunderline = false;
      chatoutputfontweight = 50.0;
      chatoutputmode = "Scrolling";
      chatoutputrelativefontsize = 24.0;
      chattimeout = 7.0;
      chattopmargin = 25.0;
      notificationtimeout = 3.0;
      showdifferentroomosd = false;
      showdurationnotification = true;
      shownoncontrollerosd = false;
      showosd = true;
      showosdwarnings = true;
      showsameroomosd = true;
      showslowdownosd = true;
    };
  };

  pass-syncplay = (pkgs.writeShellApplication {
    name = "pass-syncplay";
    runtimeInputs = [
      config.programs.password-store.package
      pkgs.coreutils
    ];

    text = ''
      umask 0077

      : "''${XDG_CONFIG_HOME:=$HOME/.config}"
      : "''${XDG_RUNTIME_DIR:=/run/user/$(id -un)}"
      runtime="''${XDG_RUNTIME_DIR}/pass-syncplay"

      hostname="$1"; shift
      port="$1"; shift

      pass=$(pass "syncplay/$hostname") || exit $?

      [ -d "$runtime" ] || mkdir -m 700 "$runtime"
      cat > "$runtime"/syncplay.ini <<EOF
      ${syncplayINI}
      [server_data]
      host = $hostname
      port = $port
      password = $pass
      EOF

      ln -sf "$runtime"/syncplay.ini "$XDG_CONFIG_HOME"/syncplay.ini
    '';
  });
in
{
  systemd.user.services."pass-syncplay" = {
    Unit = {
      Description = "Authenticate `syncplay` using `pass`";
      PartOf = [ "graphical-session.target" ];

      After = [ "gpg-agent.service" ];
    };
    Install.WantedBy = [ "graphical-session.target" ];

    Service = {
      Type = "oneshot";
      RemainAfterExit = true;

      ExecStart = [ "${pass-syncplay}/bin/pass-syncplay journcy.net 8999" ];
      ExecStop = [ "${pkgs.coreutils}/bin/rm -rf %t/pass-syncplay" ];
    };
  };

  home.packages = [ pass-syncplay pkgs.syncplay ];

  xdg.configFile = {
    "Syncplay/MainWindow.conf".text = toINI { } {
      MainWindow = {
        autoplayChecked = false;
        autoplayMinUsers = 3;
        showAutoPlayButton = true;
        showPlaybackButtons = false;
      };
    };

    "Syncplay/MoreSettings.conf".text = toINI { } {
      MoreSettings.ShowMoreSettings = true;
    };

    "Syncplay/PlayerList.conf".text = toINI { } {
      PlayerList.PlayerList = mpv;
    };
  };
}

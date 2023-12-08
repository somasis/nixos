final: prev:
let
  inherit (prev)
    lib

    jq
    python3Packages

    callPackage
    runtimeShell
    writeScript
    writeTextFile
    ;
in
lib.recursiveUpdate
  prev
  (rec {
    wrapCommand = callPackage ./wrapCommand;

    writeJqScript = name: args: text:
      let
        args' = lib.cli.toGNUCommandLineShell { } (args // {
          from-file = writeScript name ''
            #!${jq}/bin/jq -f
            ${text}
          '';
        });
      in
      writeTextFile {
        inherit name;
        executable = true;

        checkPhase = ''
          e=0
          ${jq}/bin/jq -n ${args'} || e=$?

          # 3: syntax error
          [ "$e" -eq 3 ] && exit 1 || :

          exit 0
        '';

        text = ''
          #!${runtimeShell}
          exec ${jq}/bin/jq ${args'} "$@"
        '';
      }
    ;

    screenshot = callPackage ./screenshot { };
    xinput-notify = callPackage ./xinput-notify { };

    ini2nix = callPackage ./ini2nix { };
    json2nix = callPackage ./json2nix { };

    bspwm-center-window = callPackage ./bspwm-center-window { };
    bspwm-urgent = callPackage ./bspwm-urgent { };

    ellipsis = callPackage ./ellipsis { };
    dates = callPackage ./dates { };
    mimetest = callPackage ./mimetest { };
    nocolor = callPackage ./nocolor { };
    playtime = callPackage ./playtime { };
    table = callPackage ./table { };

    dmenu = callPackage ./dmenu { };
    dmenu-emoji = callPackage ./dmenu-emoji { };
    dmenu-pass = callPackage ./dmenu-pass { };
    dmenu-run = callPackage ./dmenu-run { };
    dmenu-session = callPackage ./dmenu-session { };

    nxapi = callPackage ./nxapi { };

    pass-meta = callPackage ./pass-meta { };
    qute-pass = callPackage ./qute-pass { };

    borg-takeout = callPackage ./borg-takeout { };
    location = callPackage ./location { };
    qutebrowser-sync = callPackage ./qutebrowser-sync { };

    fcitx5-ilo-sitelen = callPackage ./fcitx5-ilo-sitelen { };

    bandcamp-collection-downloader = callPackage ./bandcamp-collection-downloader { };
    execshell = callPackage ./execshell { };
    ffsclient = callPackage ./ffsclient { };
    mail-deduplicate = final.python3Packages.callPackage ./mail-deduplicate { };
    notify-send-all = callPackage ./notify-send-all { };
    wcal = callPackage ./wcal { };

    pidgin-gnome-keyring = callPackage ./pidgin-gnome-keyring { };
    pidgin-groupchat-typing-notifications = callPackage ./pidgin-groupchat-typing-notifications { };
    purple-instagram = callPackage ./purple-instagram { };

    linja-luka = callPackage ./linja-luka { };
    linja-namako = callPackage ./linja-namako { };
    linja-pi-tomo-lipu = callPackage ./linja-pi-tomo-lipu { };
    linja-pimeja-pona = callPackage ./linja-pimeja-pona { };
    linja-pona = callPackage ./linja-pona { };
    linja-suwi = callPackage ./linja-suwi { };
    sitelen-pona-pi-lasin-lukin = callPackage ./sitelen-pona-pi-lasin-lukin { };

    kakounePlugins = import ./kakoune-plugins final prev;
  })

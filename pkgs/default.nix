{ pkgs ? import <nixpkgs> { } }@args:
let
  inherit (pkgs)
    lib

    jq
    python3Packages

    runCommandLocal

    callPackage
    runtimeShell
    writeScript
    writeTextFile
    ;
in
rec {
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

  fetchMediaFire =
    { url
    , name ? "${builtins.baseNameOf url}"
    , hash
    , postFetch ? ""
    , postUnpack ? ""
    , meta ? { }
    , ...
    } @ args:
      assert (lib.any (prefix: lib.hasPrefix prefix url) [
        "https://www.mediafire.com/file/"
        "https://mediafire.com/file/"
        "http://www.mediafire.com/file/"
        "http://mediafire.com/file/"
      ]);
      pkgs.stdenvNoCC.mkDerivation {
        inherit name url hash postFetch postUnpack meta;

        nativeBuildInputs = [
          pkgs.cacert
          pkgs.python3Packages.mediafire-dl
        ];

        outputHash = hash;
        outputHashAlgo = if hash != "" then null else "sha256";

        builder = pkgs.writeShellScript "fetch-mediafire-builder.sh" ''
          source $stdenv/setup

          download="$PWD"/download
          mkdir -p "$download"

          pushd "$download"
          mediafire-dl "$url"
          ls -CFlah
          popd

          mv "$download"/* "$out"
          rmdir "$download"
        '';
      };

  image-optimize = callPackage ./image-optimize { };
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
  sonapona = callPackage ./sonapona { };
  table = callPackage ./table { };

  wineprefix = callPackage ./wineprefix { };

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

  jhide = callPackage ./jhide { };
  twscrape = callPackage ./twscrape { };

  fcitx5-ilo-sitelen = callPackage ./fcitx5-ilo-sitelen { };

  bandcamp-collection-downloader = callPackage ./bandcamp-collection-downloader { };
  execshell = callPackage ./execshell { };
  ffsclient = callPackage ./ffsclient { };
  goris = callPackage ./goris { };
  notify-send-all = callPackage ./notify-send-all { };
  wcal = callPackage ./wcal { };
  xclickroot = callPackage ./xclickroot { };

  pidgin-gnome-keyring = callPackage ./pidgin-gnome-keyring { };
  pidgin-groupchat-typing-notifications = callPackage ./pidgin-groupchat-typing-notifications { };
  purple-instagram = callPackage ./purple-instagram { };

  linja-luka = callPackage ./linja-luka { };
  linja-namako = callPackage ./linja-namako { };
  linja-pi-tomo-lipu = callPackage ./linja-pi-tomo-lipu { };
  linja-pimeja-pona = callPackage ./linja-pimeja-pona { };
  linja-pona = callPackage ./linja-pona { };
  linja-suwi = callPackage ./linja-suwi { };

  newslinkrss = python3Packages.callPackage ./newslinkrss { };
  mail-deduplicate = python3Packages.callPackage ./mail-deduplicate { };

  kakounePlugins = import ./kakoune-plugins args;
  zotero-addons = import ./zotero-addons args;
}

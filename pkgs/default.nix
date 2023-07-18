{ pkgs
, lib ? pkgs.lib
, ...
}:
let
  inherit (pkgs)
    callPackage
    python3Packages
    ;
in
rec
{
  wrapCommand = callPackage ./wrapCommand;

  writeJqScript = callPackage ./writeJqScript;

  screenshot = callPackage ./screenshot { };
  xinput-notify = callPackage ./xinput-notify { };

  dates = callPackage ./dates { };
  json2nix = callPackage ./json2nix { };
  mimetest = callPackage ./mimetest { };
  nocolor = callPackage ./nocolor { };
  playtime = callPackage ./playtime { };
  table = callPackage ./table { };

  dmenu = callPackage ./dmenu { };
  dmenu-emoji = callPackage ./dmenu-emoji { };
  dmenu-pass = callPackage ./dmenu-pass { };
  dmenu-run = callPackage ./dmenu-run { };
  dmenu-session = callPackage ./dmenu-session { };

  pass-meta = callPackage ./pass-meta { };
  qute-pass = callPackage ./qute-pass { };

  borg-takeout = callPackage ./borg-takeout { };
  qutebrowser-sync = callPackage ./qutebrowser-sync { };

  ffsclient = callPackage ./ffsclient { };
  mail-deduplicate = python3Packages.callPackage ./mail-deduplicate { };
  notify-send-all = callPackage ./notify-send-all { };
  wcal = callPackage ./wcal { };
} // import ./trivial-builders { inherit lib pkgs; }

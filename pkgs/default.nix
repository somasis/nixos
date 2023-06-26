{ pkgs
, lib ? pkgs.lib
, ...
}:
let
  inherit (pkgs) callPackage;
in
rec
{
  wrapCommand = callPackage ./wrapCommand;

  writeJqScript = callPackage ./writeJqScript;

  screenshot = callPackage ./screenshot { };
  xinput-notify = callPackage ./xinput-notify { };

  dates = callPackage ./dates { };
  json2nix = callPackage ./json2nix { };
  nocolor = callPackage ./nocolor { };
  playtime = callPackage ./playtime { };
  table = callPackage ./table { };
  wcal = callPackage ./wcal { };

  dmenu = callPackage ./dmenu { };
  dmenu-emoji = callPackage ./dmenu-emoji { };
  dmenu-pass = callPackage ./dmenu-pass { };
  dmenu-run = callPackage ./dmenu-run { };
  dmenu-session = callPackage ./dmenu-session { };

  pass-meta = callPackage ./pass-meta { };
  qute-pass = callPackage ./qute-pass { };

  ffsclient = callPackage ./ffsclient { };
  qutebrowser-sync = callPackage ./qutebrowser-sync { };
} // import ./trivial-builders { inherit lib pkgs; }

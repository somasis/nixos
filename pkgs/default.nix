{ pkgs }:
let
  inherit (pkgs) callPackage lib;
in
rec
{
  wrapCommand = callPackage ./wrapCommand;

  screenshot = callPackage ./screenshot { };
  xinput-notify = callPackage ./xinput-notify { };

  dates = callPackage ./dates { };
  json2nix = callPackage ./json2nix { };
  nocolor = callPackage ./nocolor { };
  table = callPackage ./table { };
}

{ pkgs }:
let
  inherit (pkgs) callPackage lib;
in
rec
{
  wrapCommand = callPackage ./wrapCommand;

  screenshot = callPackage ./screenshot { };
  xinput-notify = callPackage ./xinput-notify { };

  json2nix = callPackage ./json2nix { };
  nocolor = callPackage ./nocolor { };
  table = callPackage ./table { };
}

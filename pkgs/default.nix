{ pkgs }:
let
  inherit (pkgs) callPackage lib;
in
rec
{
  screenshot = callPackage ./screenshot { };
  xinput-notify = callPackage ./xinput-notify { };
}

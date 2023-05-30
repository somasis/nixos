{ pkgs }:
let
  inherit (pkgs) callPackage lib;
in
rec
{
  screenshot = callPackage ./screenshot { };
}

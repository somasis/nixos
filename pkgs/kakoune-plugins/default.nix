{ pkgs ? import <nixpkgs> { } }:
let inherit (pkgs) callPackage; in
{
  kakoune-fcitx = callPackage ./kakoune-fcitx { };
  kakoune-find = callPackage ./kakoune-find { };
  tug = callPackage ./tug { };
  csv-kak = callPackage ./csv-kak { };
}

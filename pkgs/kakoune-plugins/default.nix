final: prev:
let
  inherit (prev) callPackage;
in
{
  kakoune-fcitx = callPackage ./kakoune-fcitx { };
  kakoune-find = callPackage ./kakoune-find { };
  tug = callPackage ./tug { };
  csv-kak = callPackage ./csv-kak { };
}

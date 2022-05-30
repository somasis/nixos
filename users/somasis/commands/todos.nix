{ pkgs, ... }: {
  home.packages = [
    (pkgs.writeScriptBin "todos" ''
      #!${pkgs.gawk}/bin/gawk -f
      /(^| )#.* (TODO|NOTE|HACK|XXX|BUG)/ {
          gsub("TODO", "\033[1;32m&\033[0m");
          # gsub("NOTE", "\033[1;34m&\033[0m");
          gsub("HACK", "\033[1;33m&\033[0m");
          # gsub("XXX", "\033[1;33m&\033[0m");
          gsub("BUG", "\033[1;31m&\033[0m");
          gsub("^ *", "");
          print FILENAME ":" FNR "\t" $0
      }
    '')
  ];
}

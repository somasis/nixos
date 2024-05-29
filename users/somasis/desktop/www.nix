{ pkgs
, ...
}: {
  persist.directories = [{ method = "symlink"; directory = "www"; }];

  home.packages = [
    pkgs.asciidoctor-with-extensions
    pkgs.curlFull
    pkgs.imagemagick
  ];

  home.shellAliases.note = ''$EDITOR "$(make -C ~/www/somas.is -s note-new)"'';
}

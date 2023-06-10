{ pkgs
, ...
}: {
  persist.directories = [{ method = "symlink"; directory = "www"; }];

  home.packages = [
    (pkgs.asciidoctor-with-extensions.override { withJava = false; })
    pkgs.curlFull
    pkgs.imagemagick
    pkgs.ruby
  ];

  home.shellAliases.note = ''$EDITOR "$(make -C ~/www/somas.is -s note-new)"'';
}

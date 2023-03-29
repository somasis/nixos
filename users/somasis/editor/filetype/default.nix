{
  imports = [
    ./c.nix
    ./nix.nix
    ./perl.nix
    ./prose.nix
    ./python.nix
    ./shell.nix
    ./troff.nix
    ./web.nix
    ./yaml.nix
  ];

  # Detect filetype for files using nix-shell.
  programs.kakoune.config.hooks = [{
    name = "BufOpenFile";
    option = ".*";
    commands = ''
      evaluate-commands %sh{
          [ -z "$kak_opt_filetype" ] || exit

          shebang=$(head -n 1 "$kak_buffile")
          case "$shebang" in
              '#!'*'/env nix-shell')
                  interpreter=''${shebang##*/env }
                  interpreter=''${interpreter%% *}
                  ;;
              '#! '*) interpreter=''${shebang#* } ;;
              '#!'*)  interpreter=''${shebang#"#!"} ;;
              *) exit ;;
          esac

          interpreter=''${interpreter%% *}
          interpreter=''${interpreter##* }
          interpreter=''${interpreter%%[0-9]*}

          case "$interpreter" in
              nix-shell)
                  # sheesh
                  filetype=$(
                      sed -E \
                          -e '/^#! *nix-shell.* -i .*/!d' \
                          -e 's/.* -i //' \
                          -e 's/ .*//' \
                          "$kak_buffile"
                  )

                  case "$filetype" in
                      bash) filetype=sh ;;
                  esac
                  ;;
              *)
                  echo "unknown interpreter: $interpreter" >&2
                  exit
                  ;;
          esac

          printf "set-option buffer filetype '%s'\n" "$filetype"
      }
    '';
  }];
}

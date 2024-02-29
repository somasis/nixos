{ lib

, symlinkJoin
, writeTextFile
, substituteAll

, coreutils
, gawk
, runtimeShell
}:
symlinkJoin {
  name = "pass-meta";

  paths = [
    (writeTextFile {
      name = "pass-meta";

      executable = true;
      destination = "/lib/password-store/extensions/meta.bash";

      text = builtins.readFile (substituteAll {
        src = ./pass-meta.bash;
        inherit coreutils gawk runtimeShell;
      });
    })

    (writeTextFile {
      name = "bash-completion-pass-meta";

      executable = true;
      destination = "/share/bash-completion/completions/pass-meta";

      text = ''
        PASSWORD_STORE_EXTENSION_COMMANDS+=( meta )

        __password_store_extension_complete_meta() {
            if [[ "$COMP_CWORD" -eq 3 ]]; then
                COMPREPLY+=( $(compgen -W "$(pass meta "''${COMP_WORDS[$COMP_CWORD-1]}")" -- "''${COMP_WORDS[COMP_CWORD]}") )
            elif [[ "$COMP_CWORD" -eq 2 ]]; then
                _pass_complete_entries 1
            fi
        }
      '';
    })
  ];

  meta = with lib; {
    description = "Retrieve metadata from pass(1) entries";
    license = licenses.unlicense;
    maintainers = with maintainers; [ somasis ];
  };
}

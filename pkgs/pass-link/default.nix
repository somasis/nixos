{ lib

, symlinkJoin
, writeTextFile

, bash
, coreutils
, gawk
, moreutils
, rsync
}:
(symlinkJoin {
  name = "pass-link";

  meta = with lib; {
    description = "Maintain symlinks in a pass(1) store, without using symlinks";
    longDescription = ''
      Maintain symbolic links between pass(1) entries in a store, without using symlinks,
      keeping their contents in sync. Symbolic links are not used so that devices which
      do not support symlinks (such as store synchronized by Syncthing to a mobile
      device) can work seamlessly.
    '';

    license = licenses.unlicense;
    maintainers = with maintainers; [ somasis ];
  };

  paths = [
    (writeTextFile {
      name = "pass-link";

      executable = true;
      destination = "/lib/password-store/extensions/link.bash";

      text = ''
        #!${lib.getExe bash}

        export PATH=${lib.makeBinPath [ coreutils gawk moreutils rsync ]}":$PATH"

        usage() {
            cat >&2 <<EOF
        usage: pass link [-nu] SOURCE TARGET...
               pass link [-nu]
        EOF
            exit 69
        }

        set -eu
        set -o pipefail

        : "''${PASSWORD_STORE_DIR:=$HOME/.password-store}"
        links="$PASSWORD_STORE_DIR/.pass-link"

        dry_run=
        target_may_update_source=false

        while getopts :nu arg >/dev/null 2>&1; do
            case "$arg" in
                n) dry_run=dry_run ;;
                u) target_may_update_source=true ;;
                *) usage ;;
            esac
        done
        shift $(( OPTIND - 1 ))

        [[ "$#" -eq 1 ]] && usage

        success=true

        dry_run() {
            echo "$@" >&2
        }

        canonicalize_links_file() {
            sort -t $'\t' -k1 \
                | while IFS=$'\t' read -r -a items; do
                    for target in "''${items[@]:1}";do
                        printf '%s\t%s\n' "''${items[0]}" "''${target}"
                    done
                done \
                | uniq
        }

        compress_canonicalized_links_file() {
            awk -F $'\t' '
                $1==last_source { printf "\t%s",$2; next }
                NR>1 { print ""; }
                { last_source=$1; printf "%s",$0; }
                END { print ""; }
            '
        }

        update_link() {
            source="$1"; shift

            for target; do
                source_path="$PASSWORD_STORE_DIR/$source"
                target_path="$PASSWORD_STORE_DIR/$target"

                if [[ -d "$PASSWORD_STORE_DIR/$source" ]] && [[ -d "$PASSWORD_STORE_DIR/$target" ]]; then
                    rsync ''${dry_run:+--dry-run} -u -LKk --delay-updates -r --mkpath --delete --delete-delay "$PASSWORD_STORE_DIR/$source"/ "$PASSWORD_STORE_DIR/$target"/
                elif [[ -d "$PASSWORD_STORE_DIR/$source" ]] && ! [[ -e "$PASSWORD_STORE_DIR/$target" ]]; then
                    mkdir -p "$PASSWORD_STORE_DIR/''${target%/*}"
                    cp -fpR "$PASSWORD_STORE_DIR/$source"/ "$PASSWORD_STORE_DIR/$target"/
                else
                    source_path="$source_path".gpg
                    target_path="$target_path".gpg

                    from_path="$source_path"
                    to_path="$target_path"

                    if ! [[ -e "$source_path" ]]; then
                        printf "error: '%s' does not exist\n" "$source" >&2
                        exit 1
                    elif [[ -e "$target_path" ]]; then
                        if [[ "$(pass show "$target" | sha256sum -)" != "$(pass show "$source" | sha256sum -)" ]]; then
                            if "$target_may_update_source"; then
                                from_path="$target_path"
                                to_path="$source_path"
                            elif ! [[ -e "$target_path" ]]; then
                                printf "warning: '%s' is newer than its source '%s', not overwriting\n" "$target" "$source" >&2
                                success=false
                                continue
                            fi
                        fi
                    fi

                    cmp -s "$from_path" "$to_path" || $dry_run cp -f "$from_path" "$to_path"
                fi
                printf '%s\t%s\n' "$source" "$target"
            done
        }

        check_sneaky_paths "$@"

        items=()
        targets=()

        (
            cat "$links"

            if [[ "$#" -ge 2 ]]; then
                arg_source="$1"; shift
                printf '%s\t%s\n' "$arg_source" "$@"
            fi
        )   | canonicalize_links_file \
            | while IFS=$'\t' read -r -a items; do
                for target in "''${items[@]:1}";do
                    update_link "''${items[0]}" "''${target}"
                done
            done \
            | compress_canonicalized_links_file \
            | sponge "$links"

        "$success" || exit 1
      '';
    })

    (writeTextFile {
      name = "pass-unlink";

      destination = "/lib/password-store/extensions/unlink.bash";
      executable = true;

      text = ''
        #!${lib.getExe bash}
        export PATH=${lib.makeBinPath [ coreutils gawk moreutils rsync ]}":$PATH"

        usage() {
            cat >&2 <<EOF
        usage: pass unlink [-n] TARGET...
        EOF
            exit 69
        }

        set -eu
        set -o pipefail

        : "''${PASSWORD_STORE_DIR:=$HOME/.password-store}"
        links="$PASSWORD_STORE_DIR/.pass-link"

        dry_run=
        target_may_update_source=false

        while getopts :nu arg >/dev/null 2>&1; do
            case "$arg" in
                n) dry_run=dry_run ;;
                *) usage ;;
            esac
        done
        shift $(( OPTIND - 1 ))

        [[ "$#" -ge 1 ]] || usage

        success=true

        dry_run() {
            echo "$@" >&2
        }

        canonicalize_links_file() {
            sort -t $'\t' -k1 \
                | while IFS=$'\t' read -r -a items; do
                    for target in "''${items[@]:1}";do
                        printf '%s\t%s\n' "''${items[0]}" "''${target}"
                    done
                done \
                | uniq
        }

        compress_canonicalized_links_file() {
            awk -F $'\t' '
                $1==last_source { printf "\t%s",$2; next }
                NR>1 { print ""; }
                { last_source=$1; printf "%s",$0; }
                END { print ""; }
            '
        }

        remove_link() {
            remove="$1"

            while read -r source targets; do
                printf '%s' "$source"

                remove_path="$PASSWORD_STORE_DIR/$remove"
                [[ -d "$remove_path" ]] || remove_path="$remove_path.gpg"

                found=false
                for target in $targets; do
                    if [[ "$target" == "$remove" ]]; then
                        found=true
                        pass rm "$target" >&2
                    else
                        printf '\t%s' "$target"
                    fi
                done

                if "$success" && ! "$found"; then
                    printf "warning: '%s' does not exist in the target list\n" "$remove" >&2
                    success=false
                fi

                printf '\n'
            done
        }

        check_sneaky_paths "$@"

        <"$links" canonicalize_links_file \
            | remove_link "$1" \
            | canonicalize_links_file \
            | compress_canonicalized_links_file \
            | sponge "$links"

        "$success" || exit 1
      '';
    })
  ];
})

{ lib
, pkgs
, config
, nixosConfig
, ...
}:
let
  repl = pkgs.writeShellScript "nixos-repl" ''
    ${nixosConfig.nix.package}/bin/nix repl \
        --argstr hostName "${nixosConfig.networking.hostName}" \
        --argstr userName "${config.home.username}" \
        "$@" --file /etc/nixos/repl.nix
  '';

  nixosRepl = pkgs.writeShellScriptBin "nixos-repl" ''
    ${repl} --argstr flake "/etc/nixos"
  '';
in
{
  home.packages = [
    # nixosRepl

    pkgs.nvd

    (pkgs.writeShellApplication {
      name = "nixos-search";

      runtimeInputs = [
        config.programs.jq.package
        nixosConfig.nix.package
        pkgs.coreutils
        pkgs.gawk
        pkgs.gnugrep
        pkgs.ncurses
        pkgs.s6-portable-utils
        pkgs.util-linux
        pkgs.xe
        pkgs.table
      ];

      text = ''
        export COLUMNS="''${COLUMNS:-$(tput cols)}"

        JOBS=''${JOBS:-0}

        usage() {
            cat >&2 <<EOF
        usage: ''${0##*/} [queries...]
        EOF
            exit 69
        }

        format() {
            if [ -t 1 ]; then
                while read -r f a v d; do
                    printf "%s\t%s\t%s\t%s\n" "$f" "$a" "$v" "$d"
                done \
                    | table \
                        -N FLAKE,ATTR,VERSION,DESC \
                        -E FLAKE,ATTR,DESC \
                        -T VERSION \
                        -c "$COLUMNS" \
                    | awk -v len="$COLUMNS" \
                        '{ if (length($0) > len) print substr($0, 1, len-3) "..."; else print; }' \
                    | eval "grep --color -i $query_grep -e '\$'"
            else
                cat
            fi
        }

        query=
        query_grep=
        for q; do
            q=$(s6-quote -d \' -u -- "$q")

            # shellcheck disable=SC2089
            query="''${query:+$query }'$q'"
            query_grep="''${query_grep:+$query_grep }-e '$q'"
        done

        # shellcheck disable=SC2090
        export query

        # shellcheck disable=SC2016
        nix flake metadata --no-write-lock-file \
            --inputs-from /etc/nixos --json \
            /etc/nixos \
            | jq -r '
                (.locks.nodes.root.inputs | paths[]) as $a
                    | {name: "\($a)", "flake": (.locks.nodes[$a].flake != false)}
                    | select(.flake != false)
                    | .name
            ' \
            | xe -j "$JOBS" -LF -s '
                eval "set -- \"$1\" $query"; \
                printf "%s\t" "$1"; \
                nix search --no-write-lock-file \
                    --inputs-from /etc/nixos --json \
                    "$@";
                printf "\n"
            ' \
            | sort \
            | while IFS="$(printf '\t')" read -r flake json; do
                jq -r --arg flake "$flake" '
                    reduce inputs as $o (.; . + $o)
                        | keys_unsorted[] as $attr
                        | .[$attr]
                        | "\($ARGS.named.flake)\t\($attr | split(".")[2:] | join("."))\t\(.version)\t\(.description)"
                ' <<EOF
        $json
        EOF
            done \
            | format
      '';
    })

    (pkgs.writeShellApplication {
      name = "nixos-update";

      runtimeInputs = [
        config.programs.jq.package
        nixosConfig.nix.package
        pkgs.coreutils
      ];

      text = ''
        verbose=
        debug=

        for a; do
          shift
          [ "$a" = "--debug" ] && debug=true && verbose=true&& continue
          [ "$a" = "--verbose" ] && verbose=true && continue
          set -- "$@" "$a"
        done

        verbose() {
            # shellcheck disable=SC2059,SC2015
            [ -n "$verbose" ] && printf "$@" >&2 || :
        }

        [ -n "$debug" ] && set -x

        nix flake metadata --json --no-write-lock-file /etc/nixos \
            | jq -r '
                .locks.nodes.root[][] as $input
                    | .locks.nodes."\($input)"
                    | (
                        .original.repo
                            // (
                                (.original.url // .original.path)
                                    | scan("^.*/(.*)")[]
                            )?
                    ) as $name
                    | (.original.ref // "") as $ref
                    | "\($input)\t\($name)\t\($ref)"' \
            | while IFS=$(printf '\t') read -r input source;do
                basename=$(basename "$source" .git)
                for d in \
                    ~/src/nix/"$input" \
                    ~/src/"$input" \
                    ~/src/nix/"$basename" \
                    ~/src/"$basename"; do
                    if git -C "$d" diff-index --quiet HEAD -- 2>/dev/null; then
                        # --atomic is used so the local trees aren't ever left in a weird state.
                        before=$(git -C "$d" rev-parse HEAD) \
                            && verbose "+ git -C \"%s\" pull -q --progress -- --atomic\n" "$d" \
                            && git -C "$d" pull -q --progress -- --atomic \
                            && after=$(git -C "$d" rev-parse HEAD) \
                            && PAGER="cat" git -c color.ui=always -C "$d" \
                                log --no-merges --reverse --oneline "$before..$after"
                        break
                    fi
                done
            done

        verbose "+ nix flake update /etc/nixos\n"
        exec nix flake update /etc/nixos
      '';
    })

    (pkgs.writeShellApplication {
      name = "nixos-edit";

      runtimeInputs = [
        pkgs.coreutils
        pkgs.findutils
        pkgs.gnugrep
        pkgs.playtime
      ];

      text = ''
        playtime || exit $?

        session_active() {
            kak -l 2>/dev/null | grep -Fq "nixos-edit" \
                && kak -c nixos-edit -ui dummy -e quit >/dev/null 2>&1
        }

        if session_active; then
            exec kak -c nixos-edit "$@"
        else
            cd /etc/nixos
            nohup kak -s nixos-edit -d >/dev/null 2>&1 &

            find . \
                \( \
                    -type f \
                    -perm -000 \
                    ! -name 'flake.lock' \
                    ! -path '*/.*' \
                \) \
                -printf '%d\t%h\tedit %p\n' \
                | LC_COLLATE=C sort -t "$(printf '\t')" -k2 \
                | cut -f3- \
                | tac \
                | kak -p nixos-edit

            exec kak -c nixos-edit "$@"
        fi
      '';
    })

    (pkgs.writeShellApplication {
      name = "nixos-dev";

      runtimeInputs = [
        config.programs.git.package
        config.programs.jq.package
        pkgs.coreutils
        pkgs.s6-portable-utils
      ];

      text = ''
        args=$(
            nix flake metadata --json --no-write-lock-file /etc/nixos \
                | jq -r '
                    .locks.nodes.root[][] as $input
                        | .locks.nodes."\($input)"
                        | (
                            .original.repo
                                // (
                                    (.original.url // .original.path)
                                        | scan("^.*/(.*)")[]
                                )?
                        ) as $name
                        | (.original.ref // "") as $ref
                        | "\($input)\t\($name)\t\($ref)"' \
                | while IFS=$(printf '\t') read -r input source;do
                    basename=$(basename "$source" .git)
                    for d in \
                        ~/src/nix/"$input" \
                        ~/src/"$input" \
                        ~/src/nix/"$basename" \
                        ~/src/"$basename"; do
                        if [ -e "$d"/.git ] && git -C "$d" diff-files --quiet; then
                            s6-quote -u -- "--override-input '$input' 'git+file://$d'"
                            break
                        elif [ -e "$d" ]; then
                            s6-quote -u -- "--override-input '$input' 'path:$d'"
                            break
                        fi
                    done
                done | tr '\n' ' '
        )

        level=-2
        for a; do
          shift
          [[ "$a" = "--quiet" ]] && level=$(( level - 1 )) && continue
          [[ "$a" = "--verbose" ]] && level=$(( level + 1 )) && continue
          set -- "$@" "$a"
        done

        if [[ "$level" -ge 0 ]]; then
            while [[ "$level" -ge 0 ]]; do
                args="$args --verbose"
                level=$(( level - 1 ))
            done
        else
            while [[ "$level" -le 0 ]]; do
                args="$args --quiet"
                level=$(( level + 1 ))
            done
        fi

        # --quiet --quiet removes the "updated input" spam
        eval "exec nixos $args \"\''${@:-switch}\""
      '';
    })

    (pkgs.writeShellApplication {
      name = "nixos";
      runtimeInputs = [
        pkgs.coreutils
        pkgs.systemd
        pkgs.nixos-rebuild
        pkgs.playtime
        pkgs.table
        config.programs.jq.package
      ];

      text = ''
        playtime || exit $?

        debug=
        verbose=

        for a; do
          shift
          [ "$a" = "--debug" ] && debug=true && verbose=true && continue
          [ "$a" = "--verbose" ] && verbose=true && continue
          set -- "$@" "$a"
        done

        export COLUMNS="''${COLUMNS:-$(tput cols || echo 80)}"

        edo() {
            # shellcheck disable=SC2015
            [ -n "$verbose" ] && printf '+ %s\n' "$*" >&2 || :
            "$@"
        }

        [ -n "$debug" ] && set -x

        # Keep the old and new revisions so we can compare them later.
        _nixos_old_system=/nix/var/nix/profiles/$(readlink /nix/var/nix/profiles/system)
        _nixos_old_home="$NIX_USER_PROFILE_DIR"/"$(readlink "$NIX_USER_PROFILE_DIR"/home-manager)"

        [ "$#" -gt 0 ] || set -- switch

        # Disable logging before the switch, just in case we touch the
        # log filesystem in a way it doesn't like...
        systemctl -q is-active systemd-journald.service && edo sudo journalctl --sync --relinquish-var

        e=0
        edo nixos-rebuild --use-remote-sudo --no-update-lock-file "''${@:-switch}" || e=$?

        systemctl -q is-active systemd-journald.service && edo sudo journalctl --flush

        [ "$e" -eq 0 ] || exit $e

        _nixos_new_system=/nix/var/nix/profiles/$(readlink /nix/var/nix/profiles/system)
        _nixos_new_home="$NIX_USER_PROFILE_DIR"/"$(readlink "$NIX_USER_PROFILE_DIR"/home-manager)"

        case "$1" in
            switch|test)
                # Start default.target again, since there might be new additions via home-manager.
                edo systemctl --user start default.target \
                    || edo systemctl --user list-dependencies default.target

                # Start graphical-session.target again, if Xorg is running.
                if [ -n "$DISPLAY" ]; then
                    edo systemctl --user start graphical-session.target \
                        || edo systemctl --user list-dependencies graphical-session.target
                fi

                journalctl \
                    --no-pager \
                    --no-full \
                    --since="$(systemctl show -P ActiveEnterTimestamp "home-manager-$USER.service")" \
                    -o json \
                    -u "home-manager-$USER.service" \
                    | jq -r 'select(._COMM != "systemd") | .MESSAGE'
                ;;
        esac

        diff_system=
        diff_home=
        {
            [ "$_nixos_new_system" = "$_nixos_old_system" ] || diff_system=$(NIXOS_DIFF_TABLE=false edo nixos-diff "$_nixos_old_system" "$_nixos_new_system")
            [ "$_nixos_new_home" = "$_nixos_old_home" ] || diff_home=$(NIXOS_DIFF_TABLE=false edo nixos-diff "$_nixos_old_home" "$_nixos_new_home")

            [ -n "$diff_home" ] && [ -n "$diff_system" ] \
                && diff_system=$(
                    grep -Fxv \
                        -f <(
                            printf '%s\n' "$diff_system" "$diff_home" \
                                | grep -v -e '^[A-Za-z0-9]' -e '^$' \
                                | sort -u \
                                | uniq -d
                        ) \
                        <<<"$diff_system"
                ) \
                && printf '\n'

            {
                [ -n "$diff_system" ] && printf '%s\n' "$diff_system" ""
                [ -n "$diff_home" ] && printf '%s\n' "$diff_home"
            } | table -T2
        } | sponge >&2
      '';
    })

    (pkgs.writeShellApplication {
      name = "nixos-diff";

      runtimeInputs = [
        pkgs.coreutils
        pkgs.findutils
        pkgs.gnused
        pkgs.ncurses
        pkgs.nvd
        pkgs.outils
        pkgs.teip
        pkgs.xe
        pkgs.table
      ];

      text = ''
        : "''${NIXOS_DIFF_TABLE:=true}"

        export COLUMNS="''${COLUMNS:-$(tput cols || echo 80)}"

        usage() {
            cat >&2 <<EOF
        usage: nixos-diff OLD NEW
        EOF
            exit 69
        }

        pretty() {
            local stdin
            stdin=$(</dev/stdin)

            printf '%s (%s -> %s)\n' "$1" "$old_generation" "$new_generation"
            printf '%s\n' "$stdin" \
                | vis -ct \
                | sed -E \
                    -e '/^((Added|Removed) packages|Version changes):$|^(<<<|>>>) /d' \
                    -e '/^\[\\\^/ {
                        s/ +#[0-9]+ +/ /
                        s/ *\\\^\[\[0m  +/\\\^\[\[0m\\t/
                    }' \
                    -e '/^Closure size:/ s/^Closure size: .+\(//; s/\)\.$/\./' \
                    -e '/^<<< /d' \
                    -e '/^>>> /d' \
                | unvis \
                | NO_COLOR=true teip -d $'\t' -f2 -- nocolor \
                | nocolor \
                | {
                    if [[ "$NIXOS_DIFF_TABLE" == 'true' ]]; then
                        table -T2
                    else
                        cat
                    fi
                }
        }

        [ "$#" -gt 0 ] || usage

        old="$1"
        new="$2"

        old_stem=$(basename "$old")
        old_stem=''${old_stem%-link}
        old_stem=''${old_stem%-[0-9]*}

        old_generation=$(basename "$old" -link)
        old_generation=''${old_generation##"$old_stem"-}

        new_generation=$(basename "$new" -link)
        new_generation=''${new_generation##"$old_stem"-}

        if [ "$#" -eq 2 ]; then
            nvd --color always diff "$old" "$new" | pretty "$old_stem"
        elif [ "$#" -eq 0 ]; then
            find /nix/var/nix/profiles \
                -mindepth 1 \
                -maxdepth 1 \
                -name 'system-*-link' \
                -type l \
                | xe -N2 nvd --color always diff \
                | pretty 'system'

            find /nix/var/nix/profiles/per-user \
                -mindepth 1 \
                -maxdepth 1 \
                -type d \
                -exec sh -c 'find "$@" \
                    -mindepth 1 \
                    -maxdepth 1 \
                    -name "home-manager-*-link" \
                    -type l \
                        | sort \
                        | tail -n2
                    ' -- {} \; \
                | xe -N2 nvd --color always diff \
                | pretty 'home-manager'
        fi
      '';
    })

    # (pkgs.writeShellScriptBin "nixos-watch" ''
    #   nixos "$@"
    #   # nixos-local-sources \
    #   #     | xe -N0 find /etc/nixos {} -type f ! -path '*/.*' \
    #   #     | rwc -pe >/dev/null 2>&1
    #   xe -N0 find /etc/nixos {} -type f ! -path '*/.*' \
    #       | rwc -pe >/dev/null 2>&1
    #   exec "$0" "$@"
    # '')
  ];
}

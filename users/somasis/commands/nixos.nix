{ pkgs
, config
, nixosConfig
, ...
}:
let
  nix = "${nixosConfig.nix.package}/bin/nix";

  repl = pkgs.writeShellScript "nixos-repl" ''
    ${nix} repl \
        --argstr hostName "${nixosConfig.networking.hostName}" \
        --argstr userName "${config.home.username}" \
        "$@" --file /etc/nixos/repl.nix
  '';

  # nixosReplCurrent = pkgs.writeShellScriptBin "nixos-repl-current" ''
  #   ${repl} --argstr flake "${outPath}"
  # '';

  nixosRepl = pkgs.writeShellScriptBin "nixos-repl" ''
    ${repl} --argstr flake "/etc/nixos"
  '';
in
{
  home.packages = [
    # nixosReplCurrent
    nixosRepl

    (pkgs.writeShellScriptBin "nixos-todos" ''
      # Find all things that really ought to be improved.
      find /etc/nixos -type f -perm -000 ! -path '*/.*' -exec todos {} +
    '')

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
      ];

      text = ''
        set -e

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
                    | column -t -s "$(printf '\t')" \
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
        nix flake metadata \
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
                nix search \
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
        set -e

        nix flake metadata --json /etc/nixos \
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
                        before=$(git -C "$d" rev-parse HEAD) \
                            && printf "+ git -C \"%s\" pull -q --progress\n" "$d" >&2 \
                            && git -C "$d" pull -q --progress \
                            && after=$(git -C "$d" rev-parse HEAD) \
                            && PAGER="cat" git -c color.ui=always -C "$d" \
                                log --no-merges --reverse --oneline "$before..$after"
                        break
                    fi
                done
            done

        printf "+ nix flake update /etc/nixos\n" >&2
        nix flake update /etc/nixos
      '';
    })

    (pkgs.writeShellScriptBin "nixos-edit" ''
      find /etc/nixos \
          -type f -perm -000 ! -path '*/.*' \
          -exec editor "$@" {} +
    '')

    (pkgs.writeShellApplication {
      name = "nixos-check";
      runtimeInputs = [ nixosConfig.nix.package ];
      text = ''nix flake check /etc/nixos'';
    })

    (pkgs.writeShellApplication {
      name = "nixos-source";

      runtimeInputs = [
        config.programs.jq.package
        nixosConfig.nix.package
        pkgs.coreutils
      ];

      text = ''
        # $ nixos-source nixpkgs#pkg

        args=( )

        for a; do
            flake=''${a%%#*}
            pkg=''${a#*#}

            flakePath=$(nix flake metadata --inputs-from /etc/nixos --json "$flake" | jq -r .path)
            # flakeResolved=$(nix flake metadata --inputs-from /etc/nixos --json "$flake" | jq -r .resolvedUrl)
            # pkgPath=$(nix path-info --inputs-from /etc/nixos "$flake#$pkg")
            pkgResolved=$(nix eval --inputs-from /etc/nixos --raw "$flake#$pkg.meta.position")

            pkgSource=$(printf '%s\n' "$pkgResolved" | sed "s|^$flakePath/||")

            pkgSourceLine=''${pkgSource##*:}
            pkgSource=''${pkgSource%:*}

            pkgFile=$(
                nix flake metadata --json /etc/nixos \
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
                            ~/src/nix/"$input/$pkgSource" \
                            ~/src/"$input/$pkgSource" \
                            ~/src/nix/"$basename/$pkgSource" \
                            ~/src/"$basename/$pkgSource"; do
                            [ -e "$d" ] && printf '%s\n' "$d" && break
                        done
                    done
            )

            args+=( "$pkgFile" )
            [ "$#" -gt 1 ] || args+=( "+''${pkgSourceLine:++$pkgSource}" )
        done

        editor "''${args[@]}"
      '';
    })

    (pkgs.writeShellApplication {
      name = "nixos-diff";

      runtimeInputs = [
        nixosConfig.nix.package
        pkgs.gnused
        pkgs.gnugrep
        pkgs.util-linux
      ];

      text = ''
        set -e

        diff=$(
            nix store diff-closures "$@" \
                | sed -E "s/\x1B\[([0-9]{1,3}(;[0-9]{1,2})?)?[mGK]//g" \
                | sed -E \
                    -e 's/^/\t/' \
                    -e '/∅ → /                   { s/→/->/g; s/: ∅ -> /\t/;                     s/^/open/; }' \
                    -e '/ε → ∅/                  { s/→/->/g; s/: ε -> ∅/\t/;                    s/^/pini/; }' \
                    -e '/ → ∅/                   { s/→/->/g; s/: /\t/; s/(, [-+]|$)/\t/; s/ε//; s/ -> ∅//g; s/^/weka/; }' \
                    -e '/ → /                    { s/→/->/g; s/: /\t/;                          s/^/kama sin/; }' \
                    -e '/: [+-][0-9\.]+ [A-z]+$/ {           s/: /\t/;                          s/^/ante suli/; }' \
                    -e '/[+-][0-9\.]+ [A-z]+$/   { s/[+-][0-9\.]+ [A-z]+/\t&/; }' \
                    -e 's/, \t/\t/' \
                    -e '/(bindMount|unmount-bindMount|unbindOrUnlink|unit-persist)\t/d'
                    # -e '/ε → ∅/d; /ε$/d; /→ ε,/d' \
                    # -e "/^[^:]+: [$(printf '\e[31;1m\e[32;1m')]/d" \
                    # -e "/: ∅ → / { s/^/install:\t/; s/∅ → //; s/: /\t/ }" \
                    # -e "/ →  ∅/ { s/^/remove:\t/; s/ → ∅//; s/: /\t/ }" \
                    # -e "/: [^ ]+ → / { s/^/upgrade:\t/; s/→/->/; s/: /\t/ }" \
                    # -e "/, / s/, /\t/" \
        )

        tab=$(printf '\t')
        {
            printf '%s\n' "$diff" | grep "^open$tab"
            printf '%s\n' "$diff" | grep "^kama sin$tab"
            printf '%s\n' "$diff" | grep "^ante suli$tab"
            printf '%s\n' "$diff" | grep "^pini$tab"
            printf '%s\n' "$diff" | grep "^weka$tab"
        } | column -t -s "$(printf '\t')" -W3

      '';
    })

    (pkgs.writeShellScriptBin "nixos-dev" ''
      set -e

      edo() { printf '+ %s\n' "$*" >&2; "$@"; }

      args=$(
          nix flake metadata --json /etc/nixos \
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

      eval "exec nixos $args \"\''${@:-switch}\""
    '')

    (pkgs.writeShellScriptBin "nixos" ''
      set -e

      edo() { printf '+ %s\n' "$*" >&2; "$@"; }

      # Keep the old and new revisions so we can compare them later.
      _nixos_old_system=$(readlink /run/current-system)

      [ "$#" -gt 0 ] || set -- switch

      # Disable logging before the switch, just in case we touch the
      # log filesystem in a way it doesn't like...
      if systemctl -q is-active systemd-journald.service; then
          edo doas journalctl --sync
          edo doas journalctl --relinquish-var
      fi

      e=0
      edo doas nixos-rebuild --no-update-lock-file "$@" || e=$?

      if systemctl -q is-active systemd-journald.service; then
          edo doas journalctl --flush
      fi

      [ "$e" -eq 0 ] || exit $e

      _nixos_new_system=$(readlink /run/current-system)

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
                  --since="$(systemctl show -P ActiveEnterTimestamp home-manager-$USER.service)" \
                  -o json \
                  -u "home-manager-$USER.service" \
                  | jq -r 'select(._COMM != "systemd") | .MESSAGE'
              ;;
      esac

      nixos-diff "$_nixos_old_system" "$_nixos_new_system"
    '')

    (pkgs.writeShellScriptBin "lolly" ''
      exec ${nix} run /etc/nixos -- "''${@:---list-all}"
    '')

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

{ pkgs, ... }:
let
  repl = pkgs.writeShellScriptBin "repl" ''
    usage() {
        cat >&2 <<EOF
    usage: ''${0##*/} [-He] [-p prompt] command...
    EOF
        exit 69
    }

    execute() {
        case "$1" in
            history) history ;;
            exit | quit)
                exit 0
                ;;
            '!')
                "''${SHELL:-/bin/sh -i}"
                ;;
            '!'*)
                s="''${1#!}"
                shift
                set -- "$s" "$@"
                eval "$@"
                ;;
            "")
                [[ "$run_when_empty" == "true" ]] && "''${default_command[@]}" "$@"
                ;;
            *)
                if [[ "$as_one_argument" == "true" ]]; then
                    eval '"''${command[@]}" "$@"'
                else
                    eval "''${command[@]}" "$@"
                fi
                ;;
        esac
    }

    prompt() {
        if [[ -n "$prompt_eval" ]]; then
            eval "$prompt_eval" >&2
        else
            printf "$prompt" >&2
        fi
    }

    history=true
    run_when_empty=false
    as_one_argument=false
    default_command=
    prompt=
    prompt_eval=

    while getopts :HeoP:d:p: opt >/dev/null 2>&1; do
        case "$opt" in
            H) history=false ;;
            e) run_when_empty=true ;;
            o) as_one_argument=true ;;
            d) default_command="$OPTARG" ;;
            P) prompt_eval="$OPTARG" ;;
            p) prompt="$OPTARG" ;;
            ?)
                usage
                ;;
        esac
    done
    shift $((OPTIND - 1))

    [[ "$#" -gt 0 ]] || usage

    if [[ "$history" = "true" ]]; then
        HISTFILE="''${XDG_CACHE_HOME:=~/.cache}/repl/''${1##*/}_history"
        mkdir -p "$XDG_CACHE_HOME/repl"
        touch "$HISTFILE"

        trap 'history -w "$HISTFILE"' EXIT
        history -r "$HISTFILE"
    fi

    trap 'printf "\n"; prompt' INT

    command=( "$@" )

    prompt_default=$(printf "%s∴ " "''${1:+$1 }")
    : "''${prompt:=$prompt_default}"
    [[ -n "$default_command" ]] || default_command=( "$@" )

    eof=false
    while :; do
        while {
            prompt
            IFS="" read -r -e -d $'\n' -a arguments || eof=true
        }; do
            [[ "$history" = "true" ]] && history -s -- "''${arguments[@]}"

            if [[ "$eof" == "true" ]]; then
                printf '\n' >&2
                exit 0
            fi

            traps=$(trap)
            execute "''${arguments[@]}"
            eval "$traps"
            unset traps

            printf '\e[0m'
        done
    done
  '';
in
{
  home.packages = [
    repl
    (
      let nmcli = "${pkgs.networkmanager}/bin/nmcli"; in
      pkgs.writeShellScriptBin "nmctl" ''
        [ $# -gt 0 ] && exec ${nmcli} -a "$@"

        export PAGER=cat

        ${nmcli} -o
        exec ${repl}/bin/repl \
            -p '\e[34mnm \e[33m∴ \e[0m' \
            ${nmcli} -a "$@"
      ''
    )
  ];
}

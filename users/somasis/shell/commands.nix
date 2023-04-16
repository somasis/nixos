{
  home.shellAliases = rec {
    # LC_COLLATE=C sorts uppercase before lowercase.
    ls = "LC_COLLATE=C ls --hyperlink=auto --group-directories-first --dereference-command-line-symlink-to-dir -AFlh -b";
    vi = "$EDITOR";

    # Quick ssh aliases
    "ascii.town" = "ssh play@ascii.town";
    "2048" = "ssh -t play@ascii.town 2048";
    "snake" = "ssh -t play@ascii.town snake";

    # Quick text editing aliases
    note = ''$EDITOR "$(make -C ~/src/www/somas.is -s note-new)"'';

    bc = "bc -q";
    diff = "diff --color";

    youtube-dl = "yt-dlp";
    ytmp3 = "yt-dlp --extract-audio --audio-format=mp3";

    g = "find -L ./ -type f \! -path '*/.*/*' -print0 | xe -0 -N0 grep -n";

    xz = "xz -T0 -9 -e";
    zstd = "zstd -T0 -19";
    gzip = "pigz -p $(( $(nproc) / 2 )) -9";

    # ... | peek | ...
    peek = "tee /dev/stderr";

    sys = "systemctl -l --legend=false";
    user = "systemctl --user";
    journal = "journalctl -e";
    syslog = "${journal} -b 0";
    userlog = "${syslog} --user";
    bus = "busctl --verbose -j";

    wget = "curl -q -Lf# -Z --no-clobber --remote-name-all --remote-header-name --remove-on-error --retry 20 --retry-delay 10";

    since = "datediff -f '%Yy %mm %ww %dd %0Hh %0Mm %0Ss'";

    table = "column -t -s $'\t'";
  };

  programs.bash.initExtra = ''
    edo() { printf '+ %s\n' "$*" >&2; "$@"; }

    # # / $ echo ./nix | p cd; pwd
    # # /nix
    # p() {
    #     local opt cmd args args_count=1 args_max=$(getconf ARG_MAX)
    #     local null=
    #     while getopts :N:0 opt >/dev/null 2>&1; do
    #         case "$opt" in
    #             N) args_count="$OPTARG" ;;
    #             0) null=true ;;
    #         esac
    #     done
    #     shift $(( OPTIND - 1 ))

    #     cmd=( "$@" )

    #     [[ $(( args_count - ''${#cmd[@]} )) -gt "$args_max" ]] && args_count="$args_max"

    #     local i=0 maxed_out=
    #     while IFS= read -r ''${null:+-d $'\0'} arg; do
    #         [[ -n "$maxed_out" ]] && args=() && maxed_out=

    #         args+=( "$arg" )
    #         i=$(( i + 1 ))

    #         [[ "$i" -eq "$args_count" ]] \
    #             && maxed_out=true \
    #             && "''${cmd[@]}" "''${args[@]}"
    #     done
    # }

    # Spawn a new terminal, detached from the current one, inheriting environment and working directory.
    newt() (
        nohup terminal "$@" >/dev/null 2>&1 &
    )
  '';
}

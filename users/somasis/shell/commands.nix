{ pkgs
, lib
, ...
}: {
  home.shellAliases = rec {
    # LC_COLLATE=C sorts uppercase before lowercase.
    ls = "LC_COLLATE=C ls --hyperlink=auto --group-directories-first --dereference-command-line-symlink-to-dir --color -AFlh -b";
    vi = "$EDITOR";

    ip = "ip --color=auto";

    # Quick ssh aliases
    "ascii.town" = "ssh play@ascii.town";
    "2048" = "ssh -t play@ascii.town 2048";
    "snake" = "ssh -t play@ascii.town snake";

    # Quick text editing aliases
    note = ''$EDITOR "$(make -C ~/src/www/somas.is -s note-new)"'';

    bc = "bc -q";
    diff = "diff --color";

    g = "find -L ./ -type f \! -path '*/.*/*' -print0 | xe -0 -N0 grep -n";

    xz = "xz -T0 -9 -e";
    zstd = "zstd -T0 -19";
    gzip = "pigz -p $(( $(nproc) / 2 )) -9";

    sys = "systemctl -l --legend=false";
    user = "systemctl --user";
    journal = "journalctl -e";
    syslog = "${journal} -b 0";
    userlog = "${syslog} --user";
    bus = "busctl --verbose -j";

    wget = "curl -q -Lf# -Z --no-clobber --remote-name-all --remote-header-name --remove-on-error --retry 20 --retry-delay 10";

    since = "datediff -f '%Yy %mm %ww %dd %0Hh %0Mm %0Ss'";

    number = "nl -b a -d '' -f n -w 1";
  };

  home.packages = [
    pkgs.nocolor
    pkgs.table
  ];

  programs.bash.initExtra = ''
    edo() { printf '+ %s\n' "$*" >&2; "$@"; }

    # ... | peek [COMMAND...] | ...
    peek() {
        if [[ "$#" -eq 0 ]]; then
            tee /dev/stderr
        else
            tee >("$@" >&2)
        fi
    }

    # Spawn a new terminal, detached from the current one, inheriting environment and working directory.
    newt() (
        nohup terminal "$@" >/dev/null 2>&1 &
    )
  '';
}

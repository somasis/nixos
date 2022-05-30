{ pkgs, ... }:
let
  shellcheckfmt = pkgs.writeShellScript "shellcheckfmt" ''
    d=$(mktemp -d)

    for f; do
        if [ "$f" = '-' ]; then
            cat "$f" >"$d"/input
            f="$d"/input
        fi

        # for when shellcheck finds issues, but can't auto-fix any of them.
        ${pkgs.shellcheck}/bin/shellcheck -f diff -x -a "$f" >/dev/null 2>&1 || e=$?

        # (there's a colon in the next line because otherwise it thinks this is a directive!
        #:shellcheck(1) says...
        # > RETURN VALUES
        # >        ShellCheck uses the following exit codes:
        # >
        # >        - 0: All files successfully scanned with no issues.
        # >
        # >        - 1: All files successfully scanned with some issues.
        # >
        # >        - 2: Some files could not be processed (e.g.  file not found).
        if [ ''${e:-0} -gt 1 ]; then
            cat "$f"
            continue
        fi

        mkfifo "$d"/diff
        ${pkgs.shellcheck}/bin/shellcheck -f diff -x -a "$f" >"$d"/diff &
        patch -p1 -s -i "$d"/diff -o - "$f" &
        wait
        rm -f "$d"/diff "$d"/input
    done
    rm -rf "$d"
  '';
  format = pkgs.writeShellScript "format" ''
    trap 'rm -f "$err" "$orig" "$new"' EXIT

    err=$(mktemp)
    orig=$(mktemp)
    new=$(mktemp)
    cat > "$orig"

    { ${shellcheckfmt} "$orig" 2>>"$err" || cat "$orig"; } | ${pkgs.shfmt}/bin/shfmt - >"$new" 2>>"$err"

    if [ "$(wc -c < "$new")" -eq 0 ]; then
        cat "$orig"
        cat "$err" >&2
        exit 1
    else
        cat "$new"
    fi
  '';
  lint = pkgs.writeShellScript "lint" ''
    (
        ${pkgs.checkbashisms}/bin/checkbashisms -l "$@" &
        ${pkgs.shellcheck}/bin/shellcheck -f gcc -x "$@" &
        wait
    ) | sort
  '';
in
{
  programs.kakoune.config.hooks = [
    {
      name = "WinSetOption";
      option = "filetype=sh";
      commands = ''
        set-option window formatcmd "${format}"
        set-option window lintcmd "${lint}"
      '';
    }
  ];

  home.file.".shellcheckrc".text = ''
    enable=all
    disable=SC2249
  '';
}

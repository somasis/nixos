{ pkgs, ... }:
let
  format = "${pkgs.perlPackages.PerlTidy}/bin/perltidy -pro=.../.perltidyrc -st -se";
  lint = pkgs.writeShellScript "lint" ''
    upward() {
        e=0
        while [ $# -gt 0 ]; do
            while [ "$PWD" != / ]; do
                [ -f "$1" ] && printf "%s\n" "$(readlink -f "$1")" && break
                e=$((e + 1))
                cd ../
            done
            shift
        done

        [ "$e" -gt 0 ] && return 1
    }

    ${pkgs.perlPackages.PerlCritic}/bin/perlcritic \
        --quiet \
        --profile "$(upward ".perlcriticrc")" \
        --verbose "%f:%l:%c: severity %s: %m [%p]\n" "$1" \
        | sed \
            -e '/: severity 5:/ s/: severity 5:/: error:/' \
            -e '/: severity [0-4]:/ s/: severity [0-4]:/: warning:/'; \
  '';
in
{
  programs.kakoune.config.hooks =
    [
      {
        name = "WinSetOption";
        option = "filetype=perl";
        commands =
          ''
            set-option window formatcmd "${format}"
            set-option window lintcmd "${lint}"
          '';
      }
    ];
}
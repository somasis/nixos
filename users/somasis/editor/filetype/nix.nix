{ pkgs
, lib
, config
, ...
}:
let
  format = pkgs.writeShellScript "format-nix" ''
    : "''${kak_buffile:="$PWD"/file.nix}"

    : "''${format_in:?format_in not set}"
    : "''${format_out:?format_out not set}"

    bufdir="''${kak_buffile%/*}"
    bufext="''${kak_buffile##*.}"

    upward() {
        local e=0
        while [ $# -gt 0 ]; do
            while [ "$PWD" != / ]; do
                [ -f "$1" ] && printf "%s\n" "$(readlink -f "$1")" && break
                e=$((e + 1))
                cd ../
            done
            shift
        done

        [ "$e" -gt 0 ] && return 1 || return 0
    }

    has_formatter() {
        nix-instantiate \
            --eval \
            --readonly-mode \
            --argstr flake "$1" \
            --expr '{ flake }: (builtins.getFlake flake).formatter.''${builtins.currentSystem}' \
            >/dev/null 2>&1
    }

    cd "''${bufdir}"
    flake=$(upward "flake.nix") && flake="''${flake%/flake.nix}" || flake=
    has_formatter=$([ -n "$flake" ] && has_formatter "$flake" && echo true || echo false)

    # `nix fmt` wants to edit in place and there's no way around it!
    cat > "$format_out"

    e=0
    if "$has_formatter"; then
        mv "$format_out" "$bufdir/.''${format_out##*/}.nix"
        nix fmt "$bufdir/.''${format_out##*/}.nix" >/dev/null || e=$?
        mv "$bufdir/.''${format_out##*/}.nix" "$format_out"
    else
        nixpkgs-fmt "$format_out" >/dev/null || e=$?
    fi

    return "$e"
  '';

  lint = pkgs.writeShellScript "lint-nix" ''
    statix check -o json "$@" 2>/dev/null \
        | jq -r '
            .file as $file
                | .report
                | map(
                    (.severity | ascii_downcase) as $severity
                        | (.note | ascii_downcase) as $note
                        | .diagnostics
                        | map("\($file):\(.at.from.line):\(.at.to.line):\(try $severity + ": ")\(.message)\(try " (" + $note + ")")")
                )
                | flatten[]
        '
  '';
in
{
  home.packages = [ pkgs.nixpkgs-fmt pkgs.statix ];

  programs.kakoune.config.hooks = [{
    name = "WinSetOption";
    option = "filetype=nix";
    commands = ''
      set-option window tabstop 2
      set-option window indentwidth 2

      set-option window formatcmd "run() { . ${format}; } && run"
      set-option window lintcmd ${lint}
    '';
  }];
}

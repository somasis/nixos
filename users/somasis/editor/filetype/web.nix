{ pkgs
, lib
, config
, ...
}:
let
  formatPrettier = pkgs.writeShellScript "format-prettier" ''
    ${pkgs.nodePackages.prettier}/bin/prettier \
        --tab-width "$kak_opt_tabstop" \
        --print-width "$kak_opt_autowrap_column" \
        --config-precedence prefer-file \
        --stdin-filepath "$kak_var_buffile"
  '';

  # CSS
  # TODO Need a new CSS linting tool; stylelint is broken with recent NixOS updates, it seems, due to
  #      not having a default configuration loaded
  # lintCSS = pkgs.writeShellScript "lint-css" ''
  #   ${pkgs.nodePackages.stylelint}/bin/stylelint --formatter unix --stdin-filename="$kak_buffile" < "$1"
  # '';

  formatHTML = pkgs.writeShellScript "format-html" ''
    ${pkgs.html-tidy}/bin/tidy \
        --quiet yes \
        --indent auto \
        --indent-spaces "$kak_opt_tabstop" \
        --tab-size "$kak_opt_tabstop" \
        --tidy-mark no \
        2>/dev/null \
        || true
  '';

  # JavaScript
  lintJavaScript = pkgs.writeShellScript "lint-javascript" ''
    PATH=${lib.makeBinPath [ pkgs.quick-lint-js pkgs.coreutils ]}
    quick-lint-js \
        --stdin \
        --path-for-config-search="$kak_buffile" \
        < "$1" 2>&1\
        | cut -d: -f2- \
        | while IFS= read -r line; do printf '%s:%s\n' "$kak_buffile" "$line"; done
  '';

  # JSON
  formatJSON = "${config.programs.jq.package}/bin/jq --indent %opt{tabstop} -S .";
  lintJSON = pkgs.writeShellScript "lint-json" ''
    PATH=${lib.makeBinPath [ config.programs.jq.package pkgs.gawk ]}

    jq < "$1" 2>&1 \
        | awk -v filename="$1" '
            / at line [0-9]+, column [0-9]+$/ {
                line=$(NF - 2);
                column=$NF;
                sub(/ at line [0-9]+, column [0-9]+$/, "");
                printf "%s:%d:%d: error: %s", filename, line, column, $0;
            }
        '
  '';
in
{
  home.packages = [ pkgs.nodePackages.prettier pkgs.quick-lint-js ];

  programs.kakoune.config.hooks = [
    # Format: CSS, JavaScript, YAML
    {
      name = "WinSetOption";
      option = "filetype=(css|javascript|yaml)";
      commands = ''
        set-option window formatcmd "run() { . ${formatPrettier}; } && run"
      '';
    }

    # Format: HTML
    {
      name = "WinSetOption";
      option = "filetype=html";
      commands = ''
        set-option window formatcmd "run() { . ${formatHTML}; } && run"
      '';
    }

    # Lint: JavaScript
    {
      name = "WinSetOption";
      option = "filetype=javascript";
      commands = ''
        set-option window lintcmd ${lintJavaScript}
      '';
    }

    # Format, lint: JSON
    {
      name = "WinSetOption";
      option = "filetype=json";
      commands = ''
        set-option window tabstop 2
        set-option window formatcmd ${formatJSON}
        set-option window lintcmd ${lintJSON}
      '';
    }
  ];
}

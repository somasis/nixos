{ pkgs
, lib
, config
, ...
}:
let
  formatPrettierWith = extraArgs: pkgs.writeShellScript "format-prettier" ''
    PATH=${lib.makeBinPath [ pkgs.nodePackages.prettier ]}

    stdin=$(</dev/stdin)

    original_args=("$@")
    set -- ${extraArgs}

    if \
        stdout=$(
            prettier \
                --stdin-filepath "$kak_buffile" \
                --config-precedence prefer-file \
                ''${kak_opt_indentwidth:+--tab-width "$kak_opt_indentwidth"} \
                ''${kak_opt_autowrap_column:+--print-width "$kak_opt_autowrap_column"} \
                "''${original_args[@]}" \
                <<<"$stdin"
        ) \
        && [[ "$?" -eq 0 ]] \
        && [[ -n "$stdout" ]]; then
        :
    else
        stdout="$stdin"
    fi

    printf '%s' "$stdout"
  '';

  formatPrettier = formatPrettierWith "";

  # CSS
  formatCSS = formatPrettierWith "--parser css";
  # TODO Need a new CSS linting tool; stylelint is broken with recent NixOS updates, it seems, due to
  #      not having a default configuration loaded
  # lintCSS = pkgs.writeShellScript "lint-css" ''
  #   ${pkgs.nodePackages.stylelint}/bin/stylelint --formatter unix --stdin-filename="$kak_buffile" < "$1"
  # '';

  # HTML
  formatHTML = formatPrettier;
  lintHTML = pkgs.writeShellScript "lint-html" ''
    : "''${kak_buffile:=}"
    ${pkgs.html-tidy}/bin/tidy \
        --markup no \
        --gnu-emacs yes \
        --quiet yes
        --write-back no \
        --tidy-mark no \
        "$1" 2>&1
  '';

  # XML
  formatXML = "${pkgs.xmlstarlet}/bin/xmlstarlet format -s %opt{tabstop}";
  # lintXML = pkgs.writeShellScript "lint-xml" ''
  #   ${pkgs.xmlstarlet}/bin/xmlstarlet validate -w
  # '';

  # JavaScript
  formatJavascript = formatPrettier;
  lintJavascript = pkgs.writeShellScript "lint-javascript" ''
    : "''${kak_buffile:=}"

    PATH=${lib.makeBinPath [ pkgs.quick-lint-js pkgs.coreutils ]}

    quick-lint-js \
        --stdin \
        --path-for-config-search="$kak_buffile" \
        < "$1" 2>&1 \
        | cut -d: -f2- \
        | while IFS= read -r line; do printf '%s:%s\n' "$kak_buffile" "$line"; done
  '';

  # JSON
  # formatJSON = "${config.programs.jq.package}/bin/jq --indent %opt{tabstop} -S .";
  formatJSON = formatPrettierWith "--parser json";
  lintJSON = pkgs.writeShellScript "lint-json" ''
    PATH=${lib.makeBinPath [ config.programs.jq.package pkgs.gawk ]}

    LC_ALL=C jq 'halt' "$1" 2>&1 \
        | awk -v filename="$1" '
            / at line [0-9]+, column [0-9]+$/ {
                line=$(NF - 2);
                column=$NF;
                sub(/ at line [0-9]+, column [0-9]+$/, "");
                printf "%s:%d:%d: error: %s", filename, line, column, $0;
            }
        '
  '';

  # YAML
  # (a "web"-related language is not really how I would mentally categorize
  # YAML, but I don't want to put the prettier function at a higher scope.)
  formatYAML = formatPrettierWith "--parser yaml";
  lintYAML = pkgs.writeShellScript "lint-yaml" ''
    PATH=${lib.makeBinPath [ pkgs.gnused pkgs.yamllint ]}

    yamllint -f parsable -s "$1" \
        | sed -E "s/ \[\(.*\)\] / \1: /"
  '';
in
{
  home.packages = [ pkgs.nodePackages.prettier pkgs.quick-lint-js pkgs.yamllint ];

  programs.kakoune.config.hooks = [
    # Format: CSS
    {
      name = "WinSetOption";
      option = "filetype=css";
      commands = ''
        set-option window formatcmd "run() { ${formatCSS}; } && run"
      '';
      # set-option window lintcmd ${lintCSS}
    }

    # Format, lint: JavaScript
    {
      name = "WinSetOption";
      option = "filetype=javascript";
      commands = ''
        set-option window tabstop 2
        set-option window indentwidth 2
        set-option window formatcmd "run() { ${formatJavascript}; } && run"
        set-option window lintcmd ${lintJavascript}
      '';
    }

    # Format, lint: YAML
    {
      name = "WinSetOption";
      option = "filetype=yaml";
      commands = ''
        set-option window formatcmd "run() { ${formatYAML}; } && run"
        set-option window lintcmd ${lintYAML}
      '';
    }

    # Format, lint: HTML
    {
      name = "WinSetOption";
      option = "filetype=html";
      commands = ''
        set-option window formatcmd "run() { ${formatHTML}; } && run"
        set-option window lintcmd ${lintHTML}
      '';
    }

    # Format: XML
    {
      name = "WinSetOption";
      option = "filetype=xml";
      commands = ''
        set-option window formatcmd "run() { ${formatXML}; } && run"
      '';
    }

    # Format, lint: JSON
    {
      name = "WinSetOption";
      option = "filetype=json";
      commands = ''
        set-option window tabstop 2
        set-option window indentwidth 2
        set-option window formatcmd "run() { ${formatJSON}; } && run"
        set-option window lintcmd ${lintJSON}
      '';
    }
  ];
}

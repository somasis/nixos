{ pkgs
, lib
, config
, ...
}:
let
  lint = pkgs.writeShellScript "lint-prose" ''
    PATH=${lib.makeBinPath [ config.programs.jq.package pkgs.proselint ]}

    proselint -j "$1" \
        | jq -r \
            --arg buffer "$1" '
                .data.errors[]
                    | (
                        "\($ARGS.named.buffer):" +
                        + "\(.line|@text):"
                        + "\(.column|@text): "
                        + "\(.severity): "
                        + .message
                        + " [\(.check)]"
                    )
        '
  '';
in
{
  home.packages = [ pkgs.proselint ];

  programs.kakoune.config.hooks = [{
    # Markup languages / prose-heavy text.
    # Used for formatting/linting plain text, emails, git(1) commits, and Markdown/AsciiDoc files
    name = "WinSetOption";
    option = "filetype=(asciidoc|git-commit|mail|markdown)";
    commands = "set-option window lintcmd ${lint}";
  }];

  xdg.configFile."proselint/config.json".text = builtins.toJSON {
    checks."typography.symbols.curly_quotes" = false;
  };
}

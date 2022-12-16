{ pkgs, config, ... }:
let
  lint = pkgs.writeShellScript "lint" ''
    ${pkgs.proselint}/bin/proselint -j "$1" \
        | ${config.programs.jq.package}/bin/jq -r '.data.errors[]
            | (
                (.line|@text) + ":" +
                (.column|@text) + ": " +
                .severity + ": " +
                .message +
                " [" + .check + "]"
            )
        ' \
        | while read -r line; do
            printf '%s:%s\n' "$1" "$line"
        done
  '';
in
{
  programs.kakoune.config.hooks = [
    # Markup languages / prose-heavy text.
    # Used for formatting/linting plain text, emails, git(1) commits, and Markdown/AsciiDoc files
    {
      name = "WinSetOption";
      option = "filetype=(asciidoc|git-commit|mail|markdown)";
      commands = ''
        set-option window lintcmd "${lint}"
      '';
    }
  ];

  xdg.configFile."proselint/config.json".text = builtins.toJSON {
    checks."typography.symbols.curly_quotes" = false;
  };
}

{ pkgs
, lib
, config
, ...
}:
let
  proselintKakoune = pkgs.writeJqScript "proselint-kakoune" { raw-output = true; } ''
    (.data.errors // [])
      | map(
        "\($ARGS.named.buffer):"
          + "\(.line):"
          + "\(.column): "
          + "\(.severity): "
          + .message
          + " [\(.check)]"
      )[]
  '';

  lint = pkgs.writeShellScript "lint-prose" ''
    ${pkgs.proselint}/bin/proselint -j "$1" | ${proselintKakoune} --arg buffer "$1"
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

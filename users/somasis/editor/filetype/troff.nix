# roff(7).
{ pkgs, ... }:
let
  lint = pkgs.writeShellScript "lint" ''
    ${pkgs.mandoc}/bin/mandoc -T lint -W warning "$1" | cut -d ' ' -f1-
  '';
in
{
  programs.kakoune.config.hooks = [
    {
      name = "WinSetOption";
      option = "filetype=troff";
      commands = ''
        set-option window lintcmd "${lint}"
      '';
    }

    # man(7) and mdoc(7).
    # Update all .Dd dates before saving.
    {
      name = "WinSetOption";
      option = "filetype=troff";
      commands = ''
        hook buffer BufWritePre .* %{
            execute-keys -draft \
                <esc>% \
                s^\.Dd<ret> \
                x \
                |date<space>+".Dd<space>%B<space>%d,<space>%Y"<ret><esc>
        }
      '';
    }

  ];
}

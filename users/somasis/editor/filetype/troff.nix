# roff(7), mdoc(7).
{ pkgs
, lib
, ...
}:
let
  lint = pkgs.writeShellScript "lint-troff" ''
    PATH=${lib.makeBinPath [ pkgs.coreutils pkgs.mandoc ]}
    mandoc -T lint -W warning "$1" | cut -d ' ' -f1-
  '';
in
{
  home.packages = [ pkgs.mandoc ];

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

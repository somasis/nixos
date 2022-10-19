{ config
, pkgs
, ...
}:
# let
#   makel =
#       (pkgs.stdenv.mkDerivation {
#         pname = "makel";
#         version = "20220124";

#         src = pkgs.fetchFromGitHub rec {
#           owner = "maandree";
#           repo = "makel";
#           rev = "0650e17761ffc45b4fc5d32287514796d6da332d";
#           sha256 = "sha256-ItZaByPpheCuSXdd9ej+ySeX3P6DYgnNNAQlAQeNEDA=";
#         };

#         buildInputs = [
#           (pkgs.stdenv.mkDerivation {
#             pname = "libgrapheme";
#             version = "20220301";

#             src = pkgs.fetchgit rec {
#               url = "git://git.suckless.org/libgrapheme";
#               rev = "1930624b9a9703c3449d2a877640e33c6d71f190";
#               sha256 = "sha256-RjvIzfT3FxqAB6l2L1eRdBiv5qb15mXDEh2m4qih1f4=";
#             };

#             makeFlags = [ "CC:=$(CC)" "PREFIX:=$(out)" ];

#             meta = with lib; {
#               description = "unicode string library";
#               license = licenses.isc;
#               maintainers = with maintainers; [ somasis ];
#               platforms = platforms.all;
#             };
#           })
#         ];

#         makeFlags = [ "CC=cc" "PREFIX=$(out)" ];

#         meta = with lib; {
#           description = "Makefile linter";
#           license = licenses.isc;
#           maintainers = with maintainers; [ somasis ];
#           platforms = platforms.all;
#         };
#       });
# in
{
  imports = [
    ./filetype
    ./plugins
  ];

  home.packages = [
    # makel

    # Used by spell.kak; see spell.nix for dictionaries
    pkgs.aspell

    # Used by editorconfig.kak
    (pkgs.writeShellScriptBin "editor" ''
      exec terminal kak "$@"
    '')

    # TODO: can remove on next Kakoune release, probably
    #       <https://github.com/mawww/kakoune/pull/4699>
  ];

  xdg.desktopEntries.kakoune = {
    name = "Kakoune";
    genericName = "Text Editor";
    comment = "Edit text files";
    icon = "kakoune";
    categories = [ "Utility" "TextEditor" ];

    exec = "kak -- %F";
    terminal = true;
    mimeType = [ "text/*" ];
    startupNotify = false;
  };

  home.sessionVariables."EDITOR" = "editor";

  xdg.mimeApps.defaultApplications."text/*" = "kakoune.desktop";

  programs.kakoune = {
    enable = true;
    config = {
      # Highlighters
      numberLines = {
        enable = true;
        highlightCursor = true;
      };

      showMatching = true;
      showWhitespace = {
        enable = true;
        space = " ";
        tab = ">";
      };

      # Wrap text in editor view
      wrapLines = {
        enable = false;

        # Keep indentation when wrapping and wrap at word breaks
        indent = true;
        word = true;

        marker = "]";

        # Wrap to 80 even when the window is bigger.
        # maxWidth = "%opt{autowrap_column}";
      };

      keyMappings = [
        # Selections
        {
          mode = "normal";
          key = "<c-a>";
          effect = "%";
        }

        # Commenting
        {
          mode = "normal";
          key = "<a-c>";
          effect = ": comment-line<ret>";
        }
        {
          mode = "normal";
          key = "<a-C>";
          effect = ": comment-block<ret>";
        }

        # Prompt shortcuts
        {
          mode = "prompt";
          key = "<c-left>";
          effect = "<a-B>";
        }
        {
          mode = "prompt";
          key = "<c-right>";
          effect = "<a-E>";
        }
      ];

      hooks = [
        # Ensure that the default scratch buffer is entirely empty. Clearing the text is annoying.
        {
          name = "BufCreate";
          option = "\\*scratch\\*";
          commands = "execute-keys <esc>%d";
        }

        {
          name = "BufWritePre";
          option = ".*";
          commands = ''
            # Make directory for buffer prior to writing it.
            nop %sh{ mkdir -p "$(dirname "$kak_hook_param")" }
          '';
        }

        # Load file-specific settings, using editorconfig, modelines, and smarttab.kak's
        {
          name = "WinCreate";
          option = ".*";
          commands = ''
            # Default to space indentation and alignmnet.
            expandtab

            # Read in all file-specific settings.
            # Modelines are higher priority than editorconfig.
            editorconfig-load
            modeline-parse

            # Don't use noexpandtab when the file is tab-indented; use smarttab so that
            # alignments can be done with spaces.
            set-option buffer aligntab false

            autoconfigtab
          '';
        }

        # pass(1) temporary files.
        {
          name = "BufCreate";
          option = "/dev/shm/pass..*";
          commands = "autowrap-disable";
        }

        # Set autowrap highlighters, and update autowrap highlighters when the option changes.
        {
          name = "WinSetOption";
          option = "autowrap_column=.*";
          commands = ''
            add-highlighter -override window/column column %opt{autowrap_column} WrapColumn
          '';
        }

        # autolint/autoformat
        {
          name = "BufWritePre";
          option = ".*";
          commands = ''
            evaluate-commands %sh{ [ -n "$kak_opt_lintcmd" ] && echo lint || echo nop }'';
        }

        {
          name = "BufWritePre";
          option = ".*";
          commands = ''
            evaluate-commands %sh{ [ -n "$kak_opt_formatcmd" ] && echo format || echo nop }'';
        }

        # # Makefile(7).
        # {
        #   name = "WinSetOption";
        #   option = "filetype=makefile";
        #   commands = ''
        #     set-option window lintcmd "${makel}"
        #   '';
        # }

        # Mail.
        {
          name = "WinSetOption";
          option = "filetype=mail";
          commands = "set-option window autowrap_column 72";
        }

        # Use tab/alt-tab for completion
        {
          name = "InsertCompletionShow";
          option = ".*";
          commands = ''
            map window insert <tab> <c-n>
            map window insert <s-tab> <c-p>
          '';
        }

        {
          name = "InsertCompletionHide";
          option = ".*";
          commands = ''
            unmap window insert <tab> <c-n>
            unmap window insert <s-tab> <c-p>
          '';
        }
      ];

      ui = {
        enableMouse = true;
        assistant = "cat";
        setTitle = true;
        statusLine = "top";
      };
    };

    extraConfig = ''
      # Less modal-feeling keybinds

      # Editor-wide keyboard shortcuts.
      evaluate-commands %sh{
          set -- \
              "<a-a>" ": buffer-previous<ret>" \
              "<a-A>" ": buffer-next<ret>" \
              "<a-d>" ": buffer *debug*<ret>" \
              "<c-n>" ": new<ret>" \
              "<c-o>" ": edit " \
              "<c-w>" ": delete-buffer<ret>" \
              "<c-q>" ": quit<ret>" \
              ; \
          while [ $# -gt 0 ]; do \
              printf 'map global normal "%s" "%s"\n' "$1" "$2"; \
              printf 'map global insert "%s" "<esc>%s"\n' "$1" "$2"; \
              shift 2; \
          done
      }

      # Buffer editing only shortcuts.
      evaluate-commands %sh{
          set -- \
              "<c-backspace>"     "bd" \
              "<a-backspace>"     "bd" \
              "<c-left>"          "b;" \
              "<c-right>"         "w;" \
              "<c-up>"            "<up>" \
              "<c-down>"          "<down>" \
              "<c-s-left>"        "B" \
              "<c-s-right>"       "W" \
              ; \
          while [ $# -gt 0 ]; do \
              printf 'map global normal "%s" "%s"\n' "$1" "$2"; \
              printf 'map global insert "%s" "<esc>%s"\n' "$1" "$2"; \
              shift 2; \
          done
      }

      # Highlight issues, nasty code, and notes, in descending order of goodness.
      add-highlighter global/ regex \b(BUG|FIXME|REMOVE)\b 1:red+bf
      add-highlighter global/ regex \b(NOTE|HACK|XXX)\b 1:yellow+bf
      add-highlighter global/ regex \b(TODO|IDEA)\b 1:green+bf

      # Highlight trailing spaces.
      add-highlighter global/highlight-trailing-spaces regex \h+$ 0:default,red+b

      # Highlight the current word the cursor is on.
      declare-option -hidden regex user_cursor_word
      set-face global UserCursorWord +bu

      hook global -group user-highlight-cursor-word NormalIdle .* %{
          evaluate-commands -draft %{
              try %{
                  execute-keys <space><a-i>w <a-k>\A\S+\z<ret>
                  set-option buffer user_cursor_word "\b\Q%val{selection}\E\b"
              } catch %{
                  set-option buffer user_cursor_word ""
              }
          }
      }

      add-highlighter global/user-highlight-cursor-word dynregex '%opt{user_cursor_word}' 0:UserCursorWord

      set-option global windowing_modules ""
      require-module "x11"

      hook -once global ModuleLoaded x11 %{
          set-option global termcmd "terminal"
      }

      # Disable startup changelog unless development version.
      set-option global startup_info_version -1
      set-face global PrimaryCursor default,rgba:657088a0,default+bi

      set-face global MatchingChar +rbi

      map global goto f '<esc>: goto-file<ret>' -docstring 'file'
      map global goto F f -docstring 'file (legacy)'
    '';

    plugins = [
      pkgs.kakounePlugins.active-window-kak
      pkgs.kakounePlugins.kakoune-state-save

      # File management commands
      (pkgs.kakouneUtils.buildKakounePluginFrom2Nix rec {
        pname = "tug";
        version = "unstable-2020-02-22";
        src = pkgs.fetchFromGitHub {
          owner = "matthias-margush";
          repo = pname;
          rev = "23adaadb795af2d86dcb3daf7af3ebe12e932441";
          sha256 = "0qldzh3gr3m7sa1hibbmf1br5lgiqwn84ggm75iin113zc67avbi";
        };
      })

      # Find and replace across buffers.
      (pkgs.kakouneUtils.buildKakounePluginFrom2Nix rec {
        pname = "kakoune-find";
        version = "unstable-2022-03-22";
        src = pkgs.fetchFromGitHub {
          owner = "occivink";
          repo = pname;
          rev = "3cd043b25688fc447eadd9b8ae254e3224391a01";
          sha256 = "1dha98rdahgjw1n21xxk7zj4dba0s8cczccklf4grr54zhm8l8ld";
        };
      })

      (pkgs.kakouneUtils.buildKakounePluginFrom2Nix {
        pname = "smarttab-kak";
        version = "unstable-2022-04-10";
        src = pkgs.fetchFromGitHub {
          owner = "andreyorst";
          repo = "smarttab.kak";
          rev = "86ac6599b13617ff938905ba4cdd8225d7eb6a2e";
          sha256 = "sha256-STLZSwQPM+gTnkA+FQOF4I0ifPTjQWpEc/95JRzvIqU=";
        };
      })

      (pkgs.kakouneUtils.buildKakounePluginFrom2Nix rec {
        pname = "kakoune-goto-file";
        version = "unstable-2018-11-01";
        src = pkgs.fetchFromGitHub {
          owner = "Delapouite";
          repo = pname;
          rev = "44b4ffad945acb635fc1a9c1c23957ff16461102";
          sha256 = "sha256-k8I9SR5ygX6Ku+6vTXIPNAp1ZxD5B/ucwTKWigpWZjk=";
        };
      })
    ];
  };

  home.persistence."/cache${config.home.homeDirectory}".directories = [ "share/kak/state-save" ];

  # TODO: Not included in home-manager 22.05
  # editorconfig = {
  #   enable = true;

  #   settings = {
  #     "*" = {
  #       tab_width = 4;
  #       insert_final_newline = true;
  #       indent_style = "space";
  #       indent_size = 4;
  #       trim_trailing_whitespace = true;

  #       # NOTE: max_line_length being enabled triggers editorconfig-load to set a highlighter
  #       #       that is annoying to override.
  #       # max_line_length          = 100

  #       # Handled by shfmt(1).
  #       # Ideally these would be hidden behind a [[shell]] block or something; that's a work-in-progress:
  #       # <https://github.com/mvdan/sh/issues/664>
  #       binary_next_line = true;
  #       switch_case_indent = true;
  #       keep_padding = true;
  #     };

  #     "*.json" = {
  #       max_line_length = 0;
  #     };

  #     "{Makefile,*.mak,*.mk}" = {
  #       indent_style = "tab";
  #     };

  #     "{*.scd,*.{0..9},*.{0-9}p}" = {
  #       max_line_length = 72;
  #     };

  #     "{*.c,*.h,*.cpp,*.hpp" = {
  #       indent_style = "tab";
  #     };

  #     "troff" = {
  #       max_line_length = 72;
  #     };
  #   };
  # };
}

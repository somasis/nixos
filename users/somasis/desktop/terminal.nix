{ config
, lib
, pkgs
, ...
}:
let
  inherit (config.lib.somasis.colors) format hex darken;

  wordSeparators = lib.concatStrings [
    # Kitty defaults
    # "@"
    # "-"
    # "."
    # "/"
    # "_"
    # "~"
    # "?"
    # "&"
    # "="
    # "%"
    # "+"
    # "#"

    # Alacritty defaults
    ","
    "│"
    "`"
    "|"
    ":"
    ''\''
    "\\\""
    "'"
    " "
    "("
    ")"
    "["
    "]"
    "{"
    "}"
    "<"
    ">"

    # More rarely occuring
    "‹"
    "›"

    # Unicode box characters/tree characters
    "─"
    "→"

    "\t"

    "¬" # Used by Kakoune for the newline indicator
    ";"

    "‘"
    "’"
    "‚"
    "‛"
    "“"
    "”"
    "„"
    "‟"

    "="
  ];
in
{
  services.sxhkd.keybindings = {
    # "super + b" = "alacritty";
    "super + b" = "kitty -1";

    # "super + shift + b" = ''
    #   alacritty --working-directory "$(${pkgs.xcwd}/bin/xcwd)"
    # '';
  };

  programs.alacritty = {
    enable = true;

    settings =
      let
        alacrittyExtendedKeys = pkgs.fetchFromGitHub {
          owner = "alexherbo2";
          repo = "alacritty-extended-keys";
          rev = "acbdcb765550b8d52eb77a5e47f5d2a0ff7a2337";
          hash = "sha256-KKzJWZ1PEKHVl7vBiRuZg8TyhE0nWohDNWxkP53amZ8=";
        };
      in
      {
        include = [ "${alacrittyExtendedKeys}/keys.yml" ];

        cursor = {
          style = {
            shape = "Beam";
            blinking = "On";
          };
          unfocused_hollow = false;
          thickness = 0.25;
          blink_interval = 750;
        };

        font.size = 10.0;

        colors = {
          primary = {
            foreground = config.theme.colors.foreground;
            background = config.theme.colors.background;
          };

          normal = {
            black = config.theme.colors.black;
            red = config.theme.colors.red;
            green = config.theme.colors.green;
            yellow = config.theme.colors.yellow;
            blue = config.theme.colors.blue;
            magenta = config.theme.colors.magenta;
            cyan = config.theme.colors.cyan;
            white = config.theme.colors.white;
          };

          bright = {
            black = config.theme.colors.brightBlack;
            red = config.theme.colors.brightRed;
            green = config.theme.colors.brightGreen;
            yellow = config.theme.colors.brightYellow;
            blue = config.theme.colors.brightBlue;
            magenta = config.theme.colors.brightMagenta;
            cyan = config.theme.colors.brightCyan;
            white = config.theme.colors.brightWhite;
          };

          footer_bar = {
            background = config.theme.colors.accent;
            foreground = "#ffffff";
          };
        };

        scrolling = {
          multiplier = 2;
          history = 20000;
        };

        selection = {
          save_to_clipboard = true;
          semantic_escape_chars = wordSeparators;
        };
      };
  };

  home.packages = [
    # (pkgs.writeShellScriptBin "xterm" ''exec alacritty "$@"'')
    (pkgs.writeShellScriptBin "xterm" ''exec kitty "$@"'')
  ];

  programs.kitty = {
    enable = true;

    font = {
      name = "monospace";
      size = 10.0;
    };

    settings = rec {
      cursor = "none";
      cursor_shape = "beam";
      cursor_beam_thickness = "1.5";
      cursor_blink_interval = ".75";
      cursor_stop_blinking_after = 0;

      foreground = config.theme.colors.foreground;
      background = config.theme.colors.background;
      selection_foreground = "none";
      selection_background = "none";

      color0 = config.theme.colors.black;
      color1 = config.theme.colors.red;
      color2 = config.theme.colors.green;
      color3 = config.theme.colors.yellow;
      color4 = config.theme.colors.blue;
      color5 = config.theme.colors.magenta;
      color6 = config.theme.colors.cyan;
      color7 = config.theme.colors.white;
      color8 = config.theme.colors.brightBlack;
      color9 = config.theme.colors.brightRed;
      color10 = config.theme.colors.brightGreen;
      color11 = config.theme.colors.brightYellow;
      color12 = config.theme.colors.brightBlue;
      color13 = config.theme.colors.brightMagenta;
      color14 = config.theme.colors.brightCyan;
      color15 = config.theme.colors.brightWhite;

      url_color = config.theme.colors.accent;
      url_style = "dotted";
      show_hyperlink_targets = true;

      wheel_scroll_multiplier = "2.0";

      scrollback_lines = 5000;
      scrollback_fill_enlarged_window = true;

      copy_on_select = "clipboard";
      placement_strategy = "top-left";

      # Mouse hiding is handled by services.unclutter.
      mouse_hide_wait = 0;

      allow_remote_control = true;

      clear_all_shortcuts = true;

      # Disable anything related to windows, tabs, etc.
      enabled_layouts = "fat";
      tab_bar_style = "hidden";
      remember_window_size = false;

      # Reading clipboard without permission is a security risk but I simply don't care :]
      clipboard_control = "write-clipboard write-primary read-clipboard read-primary";
    };

    extraConfig = ''
      # Click the link under the mouse or move the cursor even when grabbed
      # <https://sw.kovidgoyal.net/kitty/conf/#shortcut-kitty.Click-the-link-under-the-mouse-or-move-the-cursor>
      mouse_map left click ungrabbed mouse_handle_click selection link prompt

      # cell height like Alacritty
      modify_font cell_height 105%
    '';

    keybindings = {
      "ctrl+shift+n" = "launch --cwd=current";

      "ctrl+shift+c" = "copy_to_clipboard";
      "ctrl+shift+v" = "paste_from_clipboard";

      "shift+home" = "scroll_home";
      "shift+page_up" = "scroll_page_up";
      "shift+page_down" = "scroll_page_down";
      "shift+end" = "scroll_end";

      "ctrl+shift+equal" = "change_font_size all +0.5";
      "ctrl+shift+minus" = "change_font_size all -0.5";
      "ctrl+equal" = "change_font_size all 0";
    };
  };

  xdg.configFile."kitty/diff.conf".text = ''
    pygments_style          bw

    foreground              ${config.theme.colors.foreground}
    background              ${config.theme.colors.background}

    title_fg                ${config.theme.colors.foreground}
    title_bg                ${config.theme.colors.background}

    margin_fg               ${config.theme.colors.foreground}
    margin_bg               ${config.theme.colors.black}

    removed_bg              ${config.theme.colors.red}
    highlight_removed_bg    ${hex (darken .325 config.theme.colors.brightRed)}
    removed_margin_bg       ${config.theme.colors.brightRed}

    added_bg                ${config.theme.colors.green}
    highlight_added_bg      ${hex (darken .2 config.theme.colors.green)}
    added_margin_bg         ${config.theme.colors.brightGreen}

    filler_bg               ${config.theme.colors.black}

    hunk_margin_bg          ${config.theme.colors.brightCyan}
    hunk_bg                 ${config.theme.colors.cyan}

    search_fg               ${config.theme.colors.brightWhite}
    search_bg               ${config.theme.colors.accent}

    select_fg               ${config.theme.colors.brightWhite}
    select_bg               ${config.theme.colors.accent}
  '';

  programs.bash.initExtra = ''
    if [ -n "$KITTY_WINDOW_ID" ]; then
        alias \
            clipboard="kitty +kitten clipboard" \
            icat="kitty +kitten icat" \
            mosh="mosh --ssh='kitty +kitten ssh'"

        ssh() {
            # Error: The SSH kitten is meant for interactive use only, STDIN must be a terminal
            if [ -t 0 ]; then
                kitty +kitten ssh "$@"
            else
                command ssh "$@"
            fi
        }
    fi
  '';

  programs.kakoune.config.hooks = [{
    name = "ModuleLoaded";
    option = "kitty";
    commands = ''
      # Use real windows instead of Kitty's split "windows".
      set-option global kitty_window_type "os-window"
    '';
  }];

  # programs.kakoune.package =
  #   if (builtins.compareVersions pkgs.kakoune-unwrapped.version "2022.10.31") <= 0 then
  #     pkgs.kakoune-unwrapped.overrideAttrs
  #       (final: prev: {
  #         patches = [
  #           (pkgs.fetchpatch {
  #             url = "https://github.com/mawww/kakoune/commit/7c54de233486d29c3c33e4f63774b170a5945564.patch";
  #             hash = "sha256-R8zdaLj/icQkTGpkeB+9NfcaKPNssd1zHJIFuX/g/8Y=";
  #           })
  #         ];
  #       })
  #   else
  #     throw "users/somasis/desktop/terminal.nix: kakoune patch can be removed now"
  # ;

  # xresources.properties = {
  #   # xterm(1) settings
  #   "xterm*termName" = "xterm-256color";
  #   "xterm*utf8" = true;

  #   ## Input settings

  #   ### Send as Alt as expected in other terminals
  #   "xterm*metaSendsEscape" = true;

  #   ### Send ^? on backspace instead of ^H
  #   "xterm*backarrowKey" = false;
  #   "xterm.ttyModes" = "erase ^?";

  #   ## Behavior settings

  #   ### Translations (keybinds, mouse behavior)
  #   "xterm.vt100.translations" = "#override \\n\\
  #         Ctrl <Key>minus: smaller-vt-font()\\n\\
  #         Ctrl <Key>plus: larger-vt-font()\\n\\
  #         Ctrl <Key>0: set-vt-font(d)\\n\\
  #         Ctrl Shift <Key>C: copy-selection(CLIPBOARD)\\n\\
  #         Ctrl Shift <Key>V: insert-selection(CLIPBOARD)\\n\\
  #         Ctrl <Btn1Up>: exec-formatted(\"printf '%%s\\n' %s | xterm-open\", SELECT)\\n\\
  #         Ctrl Shift <Key>O: print-everything(noAttrs, noNewLine)";

  #   "xterm*printerCommand" = "xterm-open";

  #   ### Mouse selection behavior

  #   "xterm*on2Clicks" = "word";
  #   "xterm*on3Clicks" = "line";
  #   "xterm*on4Clicks" = "regex ([[:alpha:]]+://)?([[:alnum:]!#+,./=?@_~-]|(%[[:xdigit:]][[:xdigit:]]))+";

  #   #### Understand URLs as words <https://pbrisbin.com/posts/selecting_urls_via_keyboard_in_xterm/>
  #   "xterm*charClass" = [ "33:48" "37-38:48" "45-47:48" "64:48" "126:48" "61:48" "63:48" "43:48" "35:48" ];

  #   ### Clipboard behavior
  #   "xterm*selectToClipboard" = true; # Use CLIPBOARD, not PRIMARY

  #   ### Disable popup menus entirely
  #   "xterm*omitTranslation" = "popup-menu";

  #   ### Translate terminal bells as window urgency
  #   "xterm*bellIsUrgent" = true;

  #   ## Graphical settings
  #   "xterm*renderFont" = true;

  #   "xterm*pointerShape" = "left_ptr";

  #   "xterm*fullscreen" = "never";

  #   ### Fix lag with things that shift the entire terminal contents
  #   "xterm*fastScroll" = true;

  #   ### SIXEL support
  #   "xterm*decGraphicsID" = "vt340";
  #   "xterm*numColorRegisters" = 256;
  #   "xterm*sixelScrolling" = true;

  #   "xterm*internalBorder" = 0;
  #   "xterm*showMissingGlyphs" = true;

  #   ### Scrolling settings
  #   "xterm*scrollBar" = false;
  #   "xterm*scrollTtyOutput" = false;
  #   "xterm*scrollKey" = true;

  #   ### Cursor (as in, the prompt cursor) display settings
  #   "xterm*cursorUnderLine" = false;
  #   "xterm*cursorBlink" = true;
  #   "xterm*cursorOnTime" = 500;
  #   "xterm*cursorOffTime" = 500;

  #   ### Do not display boldness with a color
  #   "xterm*boldColors" = false;
  # };
}

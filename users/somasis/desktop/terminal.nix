{ config
, pkgs
, ...
}:
let
  terminal = pkgs.writeShellScriptBin "terminal" ''
    set -u

    case "''${1:-}" in
        -c | -e | -x | --command | --)
            shift
            ;;
    esac

    if [ -t 0 ] || [ -t 1 ]; then
        exec "$@"
    fi

    if [ $# -eq 0 ]; then
        exec ${config.programs.alacritty.package}/bin/alacritty
    else
        # HACK: I've not really figured out why this is needed to make some invocations start the
        #       terminal properly...
        exec ${config.programs.alacritty.package}/bin/alacritty -e "$@"
    fi
  '';
  t = "${terminal}/bin/terminal";
in
{
  services.sxhkd.keybindings = {
    "super + b" = "${t}";
    "super + shift + b" = builtins.toString (pkgs.writeShellScript "sxhkd-terminal-at-window-cwd" ''
      window_pid=$(${pkgs.xdotool}/bin/xdotool getactivewindow getwindowpid)
      window_pid_parent=$(${pkgs.procps}/bin/pgrep -P "$window_pid" | tail -n1)
      window_cwd=$(${pkgs.coreutils}/bin/readlink -f /proc/"$window_pid_parent"/cwd)
      cd "$window_cwd"
      exec ${t}
    '');
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
            foreground = "${config.xresources.properties."*foreground"}";
            background = "${config.xresources.properties."*background"}";
          };

          normal = {
            black = "${config.xresources.properties."*color0"}";
            red = "${config.xresources.properties."*color1"}";
            green = "${config.xresources.properties."*color2"}";
            yellow = "${config.xresources.properties."*color3"}";
            blue = "${config.xresources.properties."*color4"}";
            magenta = "${config.xresources.properties."*color5"}";
            cyan = "${config.xresources.properties."*color6"}";
            white = "${config.xresources.properties."*color7"}";
          };

          bright = {
            black = "${config.xresources.properties."*color8"}";
            red = "${config.xresources.properties."*color9"}";
            green = "${config.xresources.properties."*color10"}";
            yellow = "${config.xresources.properties."*color11"}";
            blue = "${config.xresources.properties."*color12"}";
            magenta = "${config.xresources.properties."*color13"}";
            cyan = "${config.xresources.properties."*color14"}";
            white = "${config.xresources.properties."*color15"}";
          };
        };

        scrolling = {
          multiplier = 2;
          history = 20000;
        };

        selections.save_to_clipboard = true;
      };
  };

  home.packages = [
    (pkgs.writeShellScriptBin "xterm" ''exec ${t}'')
    terminal
  ];

  # programs.kitty = {
  #   enable = false;

  #   settings = rec {
  #     cursor = "none";
  #     cursor_shape = "beam";
  #     cursor_beam_thickness = "1.25";
  #     cursor_blink_interval = ".75";
  #     cursor_stop_blinking_after = 0;

  #     foreground = "${config.xresources.properties."*foreground"}";
  #     background = "${config.xresources.properties."*background"}";
  #     selection_foreground = "none";
  #     selection_background = "none";

  #     color0 = "${config.xresources.properties."*color0"}";
  #     color1 = "${config.xresources.properties."*color1"}";
  #     color2 = "${config.xresources.properties."*color2"}";
  #     color3 = "${config.xresources.properties."*color3"}";
  #     color4 = "${config.xresources.properties."*color4"}";
  #     color5 = "${config.xresources.properties."*color5"}";
  #     color6 = "${config.xresources.properties."*color6"}";
  #     color7 = "${config.xresources.properties."*color7"}";
  #     color8 = "${config.xresources.properties."*color8"}";
  #     color9 = "${config.xresources.properties."*color9"}";
  #     color10 = "${config.xresources.properties."*color10"}";
  #     color11 = "${config.xresources.properties."*color11"}";
  #     color12 = "${config.xresources.properties."*color12"}";
  #     color13 = "${config.xresources.properties."*color13"}";
  #     color14 = "${config.xresources.properties."*color14"}";
  #     color15 = "${config.xresources.properties."*color15"}";
  #     url_color = color12;

  #     wheel_scroll_multiplier = "2.0";

  #     mouse_hide_wait = 0;
  #     scrollback_lines = 10000;
  #     scrollback_fill_enlarged_window = true;

  #     copy_on_select = true;
  #     draw_minimal_borders = false;
  #     placement_strategy = "top-left";

  #     # enabled_layouts = "none";
  #     tab_bar_style = "hidden";

  #     allow_remote_control = true;

  #     clear_all_shortcuts = "yes";
  #   };

  #   keybindings = {
  #     "ctrl+shift+n" = "launch --cwd=current";

  #     "ctrl+shift+c" = "copy_to_clipboard";
  #     "ctrl+shift+v" = "paste_from_clipboard";

  #     "shift+home" = "scroll_home";
  #     "shift+page_up" = "scroll_page_up";
  #     "shift+page_down" = "scroll_page_down";
  #     "shift+end" = "scroll_end";

  #     "ctrl+shift+equal" = "change_font_size all +0.5";
  #     "ctrl+shift+minus" = "change_font_size all -0.5";
  #     "ctrl+equal" = "change_font_size all 0";
  #   };
  # };

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

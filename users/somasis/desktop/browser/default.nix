{ config, osConfig, pkgs, lib, ... }:
let
  inherit (osConfig.services) tor;

  translate = pkgs.writeShellScript "translate" ''
    set -euo pipefail

    : "''${QUTE_FIFO:?}"
    PATH=${lib.makeBinPath [ pkgs.translate-shell ] }:"$PATH"

    url=$(trans -no-browser -- "$1")
    printf 'open -t -r %s\n' "$url" > "''${QUTE_FIFO}"
  '';

  yankTextAnchor = pkgs.writeShellScript "yank-text-anchor" ''
    set -euo pipefail

    PATH=${lib.makeBinPath [ config.programs.jq.package pkgs.gnused ] }

    : "''${QUTE_FIFO:?}"
    : "''${QUTE_SELECTED_TEXT:?}"
    : "''${QUTE_URL:?}"

    exec >>"''${QUTE_FIFO}"

    textStart=$(
        sed 's/^ *//; s/ *$//' <<< "$QUTE_SELECTED_TEXT" | jq -Rr '@uri'
    )

    url="''${QUTE_URL%#*}#:~:text=''${textStart}"

    printf 'yank -q inline "%s" ;; message-info "Yanked URL of highlighted text to clipboard: %s"\n' "''${url}" "''${url}"
  '';
in
{
  imports = [
    ./blocking.nix
    # ./farside.nix
    ./greasemonkey.nix
    ./open.nix
    ./reader.nix
    ./search.nix
  ];

  persist = {
    directories = [
      "etc/qutebrowser"
      # "etc/qutebrowser/userscripts"
      # "etc/qutebrowser/userstyles"
    ];

    # files = [
    #   # BUG(?): Can't make autoconfig.yml an impermanent file; I think qutebrowser
    #   #         modifies it atomically (write new file -> rename to replace) so I
    #   #         think that it gets upset when a bind mount is used.
    #   # "etc/qutebrowser/autoconfig.yml"
    #   # "etc/qutebrowser/bookmarks/urls"
    #   # "etc/qutebrowser/quickmarks"
    # ];
  };

  cache = {
    directories = [
      "share/qutebrowser/qtwebengine_dictionaries"
      "share/qutebrowser/sessions"
      "share/qutebrowser/webengine"
      "var/cache/qutebrowser"
    ];

    files = [
      "share/qutebrowser/cmd-history"
      "share/qutebrowser/cookies"
      "share/qutebrowser/history.sqlite"
      "share/qutebrowser/state"
    ];
  };

  # activation."qutebrowser-dict" = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
  #   set -e

  #   dictcli() { ${config.programs.qutebrowser.package}/share/qutebrowser/scripts/dictcli.py "$@"; }

  #   set -- ${lib.escapeShellArgs config.programs.qutebrowser.settings.spellcheck.languages}

  #   dictcli list \
  #       | sed 's/   */\t/g' \
  #       | while IFS=$(printf '\t') read -r lang _ remote local; do
  #           for l; do
  #               [ "$lang" = "$l" ] || continue
  #               case "$local" in
  #                   -)
  #                       $DRY_RUN_CMD dictcli install "$l"
  #                       ;;
  #                   "$remote")
  #                       continue
  #                       ;;
  #                   *)
  #                       $DRY_RUN_CMD dictcli update "$l"
  #                       ;;
  #               esac
  #           done
  #       done
  # '';

  home.sessionVariables."BROWSER" = "qutebrowser";

  programs.qutebrowser = {
    enable = true;

    package = pkgs.qutebrowser.override { withPdfReader = false; };

    loadAutoconfig = true;
    settings = let xres = config.xresources.properties; in rec {
      # Clear default aliases
      aliases = { };

      # Always restore open sites when qutebrowser is reopened.
      # Equivalent of Firefox's "Restore previous session" setting.
      auto_save.session = true;

      # Load a restored tab as soon as it takes focus.
      session.lazy_restore = true;

      # Unlimited tab focus switching history.
      tabs.focus_stack_size = -1;

      # Close when the last tab is closed.
      tabs.last_close = "close";

      # Open a blank page when :open is given with no arguments.
      url = rec {
        default_page = "about:blank";
        start_pages = default_page;
      };

      # I seem to have better performance with process-per-site rather than process-per-site-instance...
      qt.chromium.process_model = "process-per-site";

      completion = {
        # Shrink the completion menu to the amount of items.
        shrink = true;

        scrollbar = {
          width = 16;
          padding = 4;
        };
      };

      content = {
        # Use system proxy settings.
        proxy = "system";

        # Allow JavaScript to read from or write to the clipboard.
        javascript = {
          can_access_clipboard = true;
          can_open_tabs_automatically = true;
        };

        # Draw the background color and images also when the page is printed.
        print_element_backgrounds = false;

        # Request that websites minimize non-essential animations and motion.
        prefers_reduced_motion = true;

        # List of user stylesheet filenames to use. These apply globally.
        user_stylesheets = map builtins.toString [
          (pkgs.writeText "fonts.user.css" ''
            @font-face {
                font-family: ui-sans-serif;
                src: local(sans-serif);
            }

            @font-face {
                font-family: ui-serif;
                src: local(serif);
            }

            @font-face {
                font-family: ui-monospace;
                src: local(monospace);
            }

            @font-family {
                font-family: -apple-system;
                src: local(sans-serif);
            }

            @font-family {
                font-family: BlinkMacSystemFont;
                src: local(sans-serif);
            }
          '')

          (pkgs.writeText "highlight-anchors.user.css" ''
            h1:target,h2:target,h3:target,h4:target,h5:target,h6:target {
                background-color: #ffff00;
            }
          '')
        ];
      };

      # Languages preferences.
      spellcheck.languages = [ "en-US" "en-AU" "en-GB" "es-ES" ];
      content.headers.accept_language = lib.concatStringsSep "," [ "tok;q=0.9" "en-US;q=0.8" "en;q=0.7" "es;q=0.6" ];

      zoom = {
        # This will be unnecessary if I ever start using Wayland and don't
        # need to think about monitor DPI stuff anymore.
        default = "150%";

        mouse_divider = 2048; # Allow for more precise zooming increments.
      };

      qt.highdpi = true;

      # Fonts.
      fonts = {
        default_family = "sans-serif";
        default_size = "11pt";

        web = {
          family = rec {
            sans_serif = "sans-serif";
            serif = "serif";
            fixed = "monospace";
            standard = serif;
          };

          size.default_fixed = 14;
        };

        completion = {
          entry = "default_size monospace";
          category = "bold default_size sans-serif";
        };

        statusbar = "default_size monospace";
        keyhint = "default_size monospace";

        downloads = "11pt monospace";

        messages = {
          error = "default_size monospace";
          info = "default_size monospace";
          warning = "default_size monospace";
        };
      };

      colors.webpage.bg = "";

      # Downloads bar.
      downloads.position = "top";
      colors.downloads.start.bg = xres."*darkBackground";
      colors.downloads.stop.bg = xres."*color2";
      colors.downloads.error.bg = xres."*color1";
      colors.downloads.bar.bg = xres."*darkBackground";

      # Statusbar.
      statusbar.position = "top";

      completion.open_categories = [
        "quickmarks"
        "searchengines"
        "bookmarks"
        "history"
        "filesystem"
      ];

      colors.statusbar.normal.bg = xres."*background";
      colors.statusbar.normal.fg = xres."*foreground";

      colors.statusbar.command.bg = xres."*lightBackground";
      colors.statusbar.command.fg = xres."*lightForeground";

      colors.statusbar.insert.bg = xres."*color2";
      colors.statusbar.insert.fg = xres."*foreground";

      colors.statusbar.passthrough.bg = xres."*color4";
      colors.statusbar.passthrough.fg = xres."*foreground";

      colors.statusbar.private.bg = xres."*color5";
      colors.statusbar.private.fg = xres."*foreground";

      colors.statusbar.progress.bg = xres."*color2";

      colors.statusbar.url.fg = xres."*color4";
      colors.statusbar.url.error.fg = xres."*color9";
      colors.statusbar.url.hover.fg = xres."*color4";
      colors.statusbar.url.success.http.fg = xres."*color4";
      colors.statusbar.url.success.https.fg = xres."*color4";
      colors.statusbar.url.warn.fg = xres."*color3";

      # Prompts.

      colors.prompts.bg = xres."*lightBackground";
      colors.prompts.fg = xres."*lightForeground";
      colors.prompts.border = "1px solid ${xres."*lightBorderColor"}";
      colors.prompts.selected.bg = xres."*colorAccent";
      colors.prompts.selected.fg = xres."*foreground";

      # Completion.

      colors.completion.category.bg = xres."*lightBackground";
      colors.completion.category.fg = xres."*lightForeground";
      colors.completion.category.border.bottom = xres."*lightBackground";
      colors.completion.category.border.top = xres."*lightBackground";
      colors.completion.even.bg = xres."*lightBackground";
      colors.completion.odd.bg = xres."*lightBackground";
      colors.completion.fg = xres."*lightForeground";
      colors.completion.item.selected.bg = xres."*colorAccent";
      colors.completion.item.selected.border.bottom = xres."*colorAccent";
      colors.completion.item.selected.border.top = xres."*colorAccent";
      colors.completion.item.selected.fg = xres."*foreground";
      colors.completion.item.selected.match.fg = xres."*foreground";
      colors.completion.scrollbar.bg = xres."*lightBackground";
      colors.completion.scrollbar.fg = xres."*darkBackground";

      # Tabs.
      tabs.position = "left";

      tabs.title.format = "{perc}{audio}{current_title}";
      tabs.title.format_pinned = "{perc}{current_title}";

      tabs.favicons.scale = 1.25;
      tabs.indicator.width = 0;
      tabs.width = "20%";
      tabs.close_mouse_button = "right";
      tabs.select_on_remove = "next";

      fonts.tabs.unselected = "default_size monospace";
      fonts.tabs.selected = "bold default_size monospace";

      # Colors (themed like Arc-Dark).
      # colors.tabs.bar.bg = "#ededee";
      # colors.tabs.odd.bg = "#f5f6f7";
      # colors.tabs.even.bg = "#f5f6f7";
      colors.tabs.bar.bg = "#353946";
      colors.tabs.odd.bg = "#353946";
      colors.tabs.even.bg = "#353946";

      # colors.tabs.even.fg = xres."*background";
      # colors.tabs.odd.fg = xres."*background";
      # colors.tabs.selected.even.fg = xres."*foreground";
      # colors.tabs.selected.odd.fg = xres."*foreground";
      colors.tabs.even.fg = xres."*foreground";
      colors.tabs.odd.fg = xres."*foreground";
      colors.tabs.selected.even.fg = xres."*foreground";
      colors.tabs.selected.odd.fg = xres."*foreground";

      colors.tabs.pinned.even.bg = xres."*background";
      colors.tabs.pinned.odd.bg = xres."*background";
      colors.tabs.pinned.selected.even.bg = xres."*colorAccent";
      colors.tabs.pinned.selected.odd.bg = xres."*colorAccent";
      colors.tabs.selected.even.bg = xres."*colorAccent";
      colors.tabs.selected.odd.bg = xres."*colorAccent";

      colors.messages = rec {
        error.bg = xres."*color1";
        warning.bg = xres."*color3";
        info.bg = xres."*colorAccent";
        info.fg = xres."*foreground";

        error.border = error.bg;
        warning.border = warning.bg;
        info.border = info.bg;
      };

      colors.contextmenu = {
        menu.bg = "#ffffff";
        menu.fg = "#5c616c";
        selected.bg = xres."*colorAccent";
        selected.fg = "#ffffff";
        disabled.fg = "#a6a8ae";
      };

      # Window.
      window.title_format = "qutebrowser{title_sep}{current_title}";

      # Messages.
      messages.timeout = 5000;

      # Interacting with page elements.
      input = {
        insert_mode = {
          auto_enter = false;
          auto_leave = false;
          leave_on_load = false;
        };
      };

      url.open_base_url = true;
    };

    extraConfig = ''
      # TODO how is this done properly in programs.qutebrowser.settings?
      c.statusbar.padding = {"top": 10, "bottom": 10, "left": 6, "right": 6}
      c.tabs.padding = {"top": 10, "bottom": 9, "left": 8, "right": 8}

      config.unbind("<Escape>")
      config.unbind("F")
      config.unbind("f")
      config.unbind("gi")
      config.unbind("j")
      config.unbind("k")
      config.unbind("q")
      config.unbind("wf")
      config.unbind("r")
      config.unbind("d")
      config.unbind("b")
      config.unbind("<Ctrl+Tab>")
      config.unbind("<Ctrl+Shift+Tab>")
      config.unbind("q")
      config.unbind("<Ctrl+q>")
      config.unbind("<F11>")

      config.unbind("<Ctrl+y>", mode="prompt")
    '';

    # enableDefaultBindings = false;
    aliases = {
      translate = "spawn -u ${translate} {url}";
      yank-text-anchor = "spawn -u ${yankTextAnchor}";
    };

    keyBindings = {
      normal = {
        "zpt" = "translate";
        "ya" = "yank-text-anchor";

        "qa" = "set-cmd-text :quickmark-add {url} \"{title}\"";
        "ql" = "set-cmd-text -s :quickmark-load";
        "qd" = lib.mkMerge [ "set-cmd-text :quickmark-del {url:domain}" "fake-key -g <Tab>" ];
        "ba" = "set-cmd-text :bookmark-add {url} \"{title}\"";
        "bl" = "set-cmd-text -s :bookmark-load";

        "!" = "set-cmd-text :open !";
        "gss" = "set-cmd-text -s :open site:{url:domain}";

        ";;" = "hint all";

        # Akin to catgirl(1).
        "<Alt+Left>" = "back";
        "<Alt+Right>" = "forward";
        "<Alt+Shift+a>" = "tab-prev";
        "<Alt+a>" = "tab-next";

        # Firefox-ish.
        "<Ctrl+t>" = "open -t";
        "<Ctrl+l>" = "set-cmd-text :open {url}";
        "<Ctrl+f>" = "set-cmd-text /";
        "<Ctrl+Shift+f>" = "set-cmd-text ?";
        "<Ctrl+Shift+i>" = "devtools";

        # Emulate Tree Style Tabs keyboard shortcuts.
        "<F1>" = lib.mkMerge [
          "config-cycle tabs.show never always"
          "config-cycle statusbar.show in-mode always"
          "config-cycle scrolling.bar never always"
        ];

        # Provide some Kakoune-style keyboard shortcuts.
        "gg" = "scroll-to-perc 0";
        "ge" = "scroll-to-perc 100";
      }
      // (lib.optionalAttrs (tor.enable && tor.client.enable) {
        "cnp" = "config-cycle -p content.proxy system socks://${tor.client.socksListenAddress.addr}:${toString tor.client.socksListenAddress.port}";
      })
      ;
    };
  };

  systemd.user = rec {
    services.qutebrowser-vacuum = {
      Unit.Description = "Vacuum the qutebrowser database";

      Service = {
        Type = "oneshot";

        # Use an ExecCondition to prevent from doing maintenance while
        # qutebrowser is running.
        #
        # systemd.service(5):
        # > The behavior is like an ExecStartPre= and condition check hybrid:
        # > when an ExecCondition= command exits with exit code 1 through 254
        # > (inclusive), the remaining commands are skipped and the unit is not
        # > marked as failed. However, if an ExecCondition= command exits with
        # > 255 or abnormally (e.g. timeout, killed by a signal, etc.), the
        # > unit will be considered failed (and remaining commands will be
        # > skipped). Exit code of 0 or those matching SuccessExitStatus= will
        # > continue execution to the next command(s).
        ExecCondition = pkgs.writeShellScript "wait-for-qutebrowser" ''
          set -eu
          set -- $(${pkgs.procps}/bin/pgrep -u "''${USER:-$(${pkgs.coreutils}/bin/id -un)}" "qutebrowser")

          [ "$#" -gt 0 ] || exit 0
          ${pkgs.procps}/bin/pwait "$@"
        '';

        ExecStart = pkgs.writeShellScript "qutebrowser-vacuum" ''
          set -eu

          PATH="${lib.makeBinPath [ pkgs.sqlite pkgs.xe ]}:$PATH"

          for db in ${lib.escapeShellArgs [ "${config.xdg.dataHome}/qutebrowser/history.sqlite" ]}; do
              sqlite3 "$db" <<'EOF'
          .timeout ${builtins.toString (60 * 1000)}
          VACUUM;
          EOF
          done
        '';

        Nice = 19;
        CPUSchedulingPolicy = "idle";
        IOSchedulingClass = "idle";
        IOSchedulingPriority = 7;
      };
    };

    timers.qutebrowser-vacuum = {
      Unit = {
        Description = "${services.qutebrowser-vacuum.Unit.Description} every week";
        PartOf = [ "timers.target" ];
      };
      Install.WantedBy = [ "timers.target" ];

      Timer = {
        OnCalendar = "weekly";
        Persistent = true;
        AccuracySec = "15m";
        RandomizedDelaySec = "5m";
      };
    };
  };

  somasis.tunnels.tunnels = [
    { name = "kodi-remote"; location = 45780; remote = "somasis@spinoza.7596ff.com"; remoteLocation = 8080; }
    { name = "kodi-websockets"; location = 9090; remote = "somasis@spinoza.7596ff.com"; remoteLocation = 9090; }
  ];

  home.packages = [ pkgs.qutebrowser-sync ];
}

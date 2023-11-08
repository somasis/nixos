{ config
, osConfig
, pkgs
, lib
, ...
}:
let
  inherit (osConfig.services) tor;

  translate = pkgs.writeShellScript "translate" ''
    set -euo pipefail

    : "''${QUTE_FIFO:?}"
    PATH=${lib.makeBinPath [ pkgs.translate-shell ] }:"$PATH"

    url=$(trans -no-browser -- "$1")
    printf 'open -t -r %s\n' "$url" > "''${QUTE_FIFO}"
  '';

  yank-text-anchor = pkgs.writeShellScript "yank-text-anchor" ''
    set -euo pipefail

    PATH=${lib.makeBinPath [ config.programs.jq.package pkgs.coreutils pkgs.gnused pkgs.trurl pkgs.util-linux ]}

    : "''${QUTE_FIFO:?}"
    exec >>"''${QUTE_FIFO}"

    : "''${QUTE_SELECTED_TEXT:-}"
    if [ -z "$QUTE_SELECTED_TEXT" ]; then
        printf 'message-error "%s"\n' "yank-text-anchor: no text selected"
        exit 1
    fi

    : "''${QUTE_URL:?}"

    # Strip fragment (https://hostname.com/index.html#fragment).
    url=$(trurl -s fragment= -f - <<<"$QUTE_URL")

    # Strip trailing newline.
    text_start=$(printf '%s' "$QUTE_SELECTED_TEXT")

    text_end=
    text_start=$(
        sed \
            -e 's/^[[:space:]][[:space:]]*//' \
            -e 's/[[:space:]][[:space:]]*$//' \
            <<<"$text_start"
    )

    if [ "''${#text_start}" -ge 300 ]; then
        # Use range-based matching if >=300 characters in text.
        text_end=$(<<<"$text_start" tr -d '\n' | tr '[:space:]' ' ' | rev | cut -d' ' -f1-5 | rev)
        text_start=$(<<<"$text_start" tr '[:space:]' ' ' | cut -d ' ' -f1-5)
    fi

    if [ -n "$text_end" ]; then
        text_end=$(jq -Rr '@uri' <<<"$text_end")
    fi

    text_start=$(jq -Rr '@uri' <<<"$text_start")

    url="$url#:~:text=$text_start''${text_end:+,$text_end}"

    printf 'yank -q inline "%s" ;; message-info "Yanked URL of highlighted text to clipboard: %s"\n' "''${url}" "''${url}"
  '';

  proxies =
    [ "system" ]
    ++ (lib.optional (tor.enable && tor.client.enable)
      "socks://${tor.client.socksListenAddress.addr}:${toString tor.client.socksListenAddress.port}"
    )
    ++ (lib.mapAttrsToList
      (_: tunnel: "socks://127.0.0.1:${toString tunnel.port}")
      (lib.filterAttrs (_: tunnel: tunnel.type == "dynamic") config.somasis.tunnels.tunnels)
    )
  ;
in
{
  imports = [
    ./greasemonkey
    ./blocking.nix
    ./open.nix
    ./reader.nix
    ./search.nix
  ];

  persist = {
    directories = [ "etc/qutebrowser" ];

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

  home.sessionVariables."BROWSER" = "qutebrowser";

  programs.qutebrowser = {
    enable = true;

    package = pkgs.qutebrowser.override {
      withPdfReader = false;
      enableWideVine = true;
    };

    loadAutoconfig = true;

    settings = rec {
      changelog_after_upgrade = "patch";

      logging.level.console = "error";

      # Clear default aliases
      aliases = { };

      # Always restore open sites when qutebrowser is reopened.
      # Equivalent of Firefox's "Restore previous session" setting.
      auto_save.session = true;

      # Load a restored tab as soon as it takes focus.
      session.lazy_restore = true;

      # Unlimited tab focus switching history.
      tabs = {
        focus_stack_size = -1;
        undo_stack_size = -1;
      };

      completion.cmd_history_max_items = 10000;

      # Close when the last tab is closed.
      tabs.last_close = "close";

      # Open a blank page when :open is given with no arguments.
      url = rec {
        default_page = "about:blank";
        start_pages = default_page;
      };

      completion = {
        # Shrink the completion menu to the amount of items.
        shrink = true;

        scrollbar = {
          width = 16;
          padding = 4;
        };
      };

      hints = {
        uppercase = true;
        radius = 0;
        border = "1px solid ${config.theme.colors.accent}";
      };

      keyhint.radius = 0;
      prompt.radius = 0;

      content = {
        proxy = builtins.toString (builtins.head proxies);

        tls.certificate_errors = "ask-block-thirdparty";

        javascript = {
          # Allow JavaScript to read from or write to the xos-upclipboard.
          clipboard = "access-paste";
          can_open_tabs_automatically = true;
        };

        # Draw the background color and images also when the page is printed.
        print_element_backgrounds = false;

        # Request that websites minimize non-essential animations and motion.
        prefers_reduced_motion = true;

        # List of user stylesheet filenames to use. These apply globally.
        user_stylesheets = map builtins.toString [
          (pkgs.writeText "system-fonts.user.css" ''
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

          (pkgs.writeText "system-highlight-color.user.css" ''
            :focus {
                outline-color: ${config.lib.somasis.colors.rgb config.theme.colors.accent};
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
      content.headers.accept_language = lib.concatStringsSep "," [ "en-US;q=0.9" "tok;q=0.8" "en;q=0.7" "es;q=0.6" ];

      # Use the actual title for notification titles, rather
      # than the site's URL of origin.
      content.notifications.show_origin = false;

      zoom.mouse_divider = 2048; # Allow for more precise zooming increments.

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

        contextmenu = "10pt sans-serif";
        tooltip = "10pt sans-serif";

        downloads = "11pt monospace";

        messages = {
          error = "default_size monospace";
          info = "default_size monospace";
          warning = "default_size monospace";
        };
      };

      # Downloads bar.
      downloads.position = "bottom";

      # Statusbar.
      statusbar.position = "top";
      statusbar.widgets = [
        "keypress"
        "url"
        "scroll"
        "history"
        "tabs"
        "progress"
      ];

      completion.open_categories = [
        "quickmarks"
        "searchengines"
        "bookmarks"
        "history"
        "filesystem"
      ];

      colors = {
        webpage.bg = "";

        downloads = {
          start.bg = config.theme.colors.darkBackground;
          stop.bg = config.theme.colors.green;
          error.bg = config.theme.colors.red;
          bar.bg = config.theme.colors.darkBackground;
        };

        statusbar = {
          normal.bg = config.theme.colors.background;
          normal.fg = config.theme.colors.foreground;

          command.bg = config.theme.colors.lightBackground;
          command.fg = config.theme.colors.lightForeground;

          insert.bg = config.theme.colors.green;
          insert.fg = config.theme.colors.foreground;

          passthrough.bg = config.theme.colors.blue;
          passthrough.fg = config.theme.colors.foreground;

          private.bg = config.theme.colors.magenta;
          private.fg = config.theme.colors.foreground;

          progress.bg = config.theme.colors.green;

          url = {
            fg = config.theme.colors.green;
            hover.fg = config.theme.colors.yellow;

            error.fg = config.theme.colors.brightRed;
            warn.fg = config.theme.colors.yellow;

            success.http.fg = config.theme.colors.yellow;
            success.https.fg = config.theme.colors.green;
          };
        };

        tooltip.bg = "#474d5d";
        tooltip.fg = "#bac3cf";

        keyhint = {
          bg = config.theme.colors.background;
          fg = config.theme.colors.foreground;
          suffix.fg = config.theme.colors.red;
        };

        prompts = {
          bg = config.theme.colors.lightBackground;
          fg = config.theme.colors.lightForeground;
          border = "1px solid ${config.theme.colors.lightBorder}";
          selected.bg = config.theme.colors.accent;
          selected.fg = config.theme.colors.foreground;
        };

        completion = {
          category = {
            bg = config.theme.colors.lightBackground;
            fg = config.theme.colors.lightForeground;
            border.bottom = config.theme.colors.lightBackground;
            border.top = config.theme.colors.lightBackground;
          };

          even.bg = config.theme.colors.lightBackground;
          odd.bg = config.theme.colors.lightBackground;
          fg = config.theme.colors.lightForeground;

          item.selected = {
            bg = config.theme.colors.accent;
            border.bottom = config.theme.colors.accent;
            border.top = config.theme.colors.accent;
            fg = config.theme.colors.foreground;
            match.fg = config.theme.colors.foreground;
          };

          scrollbar.bg = config.theme.colors.lightBackground;
          scrollbar.fg = config.theme.colors.darkBackground;
        };

        tabs = {
          bar.bg = config.theme.colors.sidebar;
          odd.bg = config.theme.colors.sidebar;
          even.bg = config.theme.colors.sidebar;

          even.fg = config.theme.colors.foreground;
          odd.fg = config.theme.colors.foreground;
          selected = {
            even.bg = config.theme.colors.accent;
            even.fg = config.theme.colors.foreground;
            odd.bg = config.theme.colors.accent;
            odd.fg = config.theme.colors.foreground;
          };

          pinned = {
            even.bg = config.theme.colors.background;
            odd.bg = config.theme.colors.background;
            selected.even.bg = config.theme.colors.accent;
            selected.odd.bg = config.theme.colors.accent;
          };
        };

        messages = rec {
          error.bg = config.theme.colors.red;
          warning.bg = config.theme.colors.yellow;
          info.bg = config.theme.colors.accent;
          info.fg = config.theme.colors.foreground;

          error.border = error.bg;
          warning.border = warning.bg;
          info.border = info.bg;
        };

        contextmenu = {
          menu.bg = "#ffffff";
          menu.fg = "#5c616c";
          selected.bg = config.theme.colors.accent;
          selected.fg = "#ffffff";
          disabled.fg = "#a6a8ae";
        };
      };

      # Tabs.
      tabs.position = "left";

      tabs.title.format = "{perc}{audio}{current_title}";
      tabs.title.format_pinned = "{perc}{current_title}";

      tabs.favicons.scale = 1.25;
      tabs.indicator.width = 0;
      tabs.width = "16%";
      tabs.close_mouse_button = "right";
      tabs.select_on_remove = "next";

      fonts.tabs.unselected = "default_size monospace";
      fonts.tabs.selected = "bold default_size monospace";

      # Window.
      window.title_format = "qutebrowser{title_sep}{host}{title_sep}{current_title}";

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
      c.statusbar.padding = {"top": 7, "bottom": 7, "left": 4, "right": 4}
      c.tabs.padding = {"top": 7, "bottom": 6, "left": 6, "right": 6}

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
      yank-text-anchor = "spawn -u ${yank-text-anchor}";
    };

    keyBindings = {
      passthrough."<Shift+Escape>" = "mode-leave";
      normal = {
        "<Shift+Escape>" = "mode-enter passthrough";

        "zpt" = "translate";
        "ya" = "yank-text-anchor";

        "ql" = "cmd-set-text -s :quickmark-load";
        "qL" = "bookmark-list";
        "qa" = "cmd-set-text -s :quickmark-add {url} \"{url:host}\"";
        "qd" = lib.mkMerge [ "cmd-set-text :quickmark-del {url:domain}" "fake-key -g <Tab>" ];

        "bl" = "cmd-set-text -s :bookmark-load";
        "bL" = "bookmark-list -j";
        "ba" = "cmd-set-text -s :bookmark-add {url} \"{title}\"";
        "bd" = lib.mkMerge [ "cmd-set-text :bookmark-del {url:domain}" "fake-key -g <Tab>" ];

        "!" = "cmd-set-text :open !";
        "gss" = "cmd-set-text -s :open site:{url:domain}";

        "cnp" = ''config-cycle -p content.proxy ${lib.concatStringsSep " " proxies}'';

        ";;" = "hint all";

        # Akin to catgirl(1).
        "<Alt+Left>" = "back --quiet";
        "<Alt+Right>" = "forward --quiet";
        "<Alt+Up>" = "navigate up";
        "<Alt+Shift+a>" = "tab-prev";
        "<Alt+a>" = "tab-next";

        # Firefox-ish.
        "<Ctrl+r>" = "reload";
        "<Ctrl+Shift+r>" = "reload -f";
        "<Ctrl+t>" = "open -t";
        "<Ctrl+l>" = "cmd-set-text :open {url}";
        "<Ctrl+f>" = "cmd-set-text /";
        "<Ctrl+Shift+f>" = "cmd-set-text ?";
        "<Ctrl+Shift+i>" = "devtools window";

        # Emulate Tree Style Tabs keyboard shortcuts.
        "<F1>" = lib.mkMerge [
          "config-cycle tabs.show never always"
          "config-cycle statusbar.show in-mode always"
          "config-cycle scrolling.bar never always"
        ];

        # Provide some Kakoune-style keyboard shortcuts.
        "gg" = "scroll-to-perc 0";
        "ge" = "scroll-to-perc 100";

        "zsm" = "open -rt https://mastodon.social/authorize_interaction?uri={url}";
        "zst" = "open -rt https://twitter.com/share?url={url}";

        "cnt" =
          lib.optionalString
            (tor.enable
              && tor.client.enable
              && tor.settings.ControlPort != [ ]
              && tor.settings.ControlPort != null)
            "spawn --userscript tor_identity"
        ;
      };
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

  somasis.tunnels.tunnels = {
    kodi-remote = {
      port = 45780;
      remote = "somasis@spinoza.7596ff.com";
      remotePort = 8080;
    };

    kodi-websockets = {
      port = 9090;
      remote = "somasis@spinoza.7596ff.com";
      remotePort = 9090;
    };

    proxy-spinoza = {
      type = "dynamic";
      port = 9099;
      remote = "somasis@spinoza.7596ff.com";
    };
  };

  home.packages = [ pkgs.qutebrowser-sync ];

  # services.dunst.settings.zz-qutebrowser = {
  #   desktop_entry = "org.qutebrowser.qutebrowser";
  # };
}

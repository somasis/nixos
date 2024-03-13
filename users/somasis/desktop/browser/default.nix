{ config
, osConfig
, pkgs
, lib
, ...
}:
let
  inherit (config.lib.somasis) xdgConfigDir xdgCacheDir xdgDataDir;
  inherit (osConfig.services) tor;

  tc = config.theme.colors;

  translate = pkgs.writeShellScript "translate" ''
    set -euo pipefail

    : "''${QUTE_FIFO:?}"
    : "''${QUTE_URL:=''${1?no URL was provided}}"
    PATH=${lib.makeBinPath [ pkgs.translate-shell ] }:"$PATH"

    url=$(trans -no-browser -- "$QUTE_URL")
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
    ./reader.nix
    ./search.nix
  ];

  persist = {
    directories = [
      (xdgConfigDir "qutebrowser")
      (xdgConfigDir "chromium")
    ];

    # files = [
    #   # BUG(?): Can't make autoconfig.yml an impermanent file; I think qutebrowser
    #   #         modifies it atomically (write new file -> rename to replace) so I
    #   #         think that it gets upset when a bind mount is used.
    #   # (xdgConfigDir "qutebrowser/autoconfig.yml")
    #   # (xdgConfigDir "qutebrowser/bookmarks/urls")
    #   # (xdgConfigDir "qutebrowser/quickmarks")
    # ];
  };

  cache = {
    directories = [
      (xdgDataDir "qutebrowser/qtwebengine_dictionaries")
      (xdgDataDir "qutebrowser/sessions")
      (xdgDataDir "qutebrowser/webengine")
      (xdgCacheDir "qutebrowser")
      (xdgCacheDir "chromium")
    ];

    files = [
      (xdgDataDir "qutebrowser/cmd-history")
      (xdgDataDir "qutebrowser/cookies")
      (xdgDataDir "qutebrowser/history.sqlite")
      (xdgDataDir "qutebrowser/state")
    ];
  };

  home.sessionVariables."BROWSER" = "qutebrowser";
  xdg.mimeApps = {
    defaultApplications = lib.genAttrs
      [
        "application/xhtml"
        "text/html"
        "text/xml"
        "x-scheme-handler/http"
        "x-scheme-handler/https"
        "x-scheme-handler/about"
        "x-scheme-handler/unknown"
      ]
      (_: "org.qutebrowser.qutebrowser.desktop")
    ;

    # associations.removed = lib.genAttrs
    #   [
    #     "application/xhtml"
    #     "text/html"
    #     "text/xml"
    #     "x-scheme-handler/http"
    #     "x-scheme-handler/https"
    #     "x-scheme-handler/about"
    #     "x-scheme-handler/unknown"
    #   ]
    #   (_: "chromium.desktop")
    # ;
  };

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
        border = "1px solid ${tc.accent}";
      };

      keyhint.radius = 0;
      prompt.radius = 0;

      content = {
        proxy = builtins.toString (builtins.head proxies);

        webrtc_ip_handling_policy = "default-public-interface-only";

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

          # NOTE: causes problems with some websites (Twitter, for example) not showing
          #       anything when highlighting text in input boxes and textareas.
          # (pkgs.writeText "system-highlight-color.user.css" ''
          #   :focus {
          #       outline-color: ${config.lib.somasis.colors.rgb tc.accent};
          #   }
          # '')

          (pkgs.writeText "highlight-anchors.user.css" ''
            h1:target,h2:target,h3:target,h4:target,h5:target,h6:target {
                background-color: #ffff00;
            }
          '')
        ];
      };

      # Languages preferences.
      spellcheck.languages = [ "en-US" "en-AU" "en-GB" "es-ES" ];
      content.headers.accept_language = lib.concatStringsSep "," (lib.reverseList (lib.imap1
        (i: v: ''${v};q=${lib.substring 0 5 (builtins.toString (i * .001))}'')
        (lib.reverseList [
          "en-US"
          "en"
          "tok"
          "es"
        ])
      ));

      # Use the actual title for notification titles, rather
      # than the site's URL of origin.
      content.notifications.show_origin = false;

      confirm_quit = [ "downloads" ];

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
        hints = "default_size monospace";

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
          start.bg = tc.darkBackground;
          stop.bg = tc.green;
          error.bg = tc.red;
          bar.bg = tc.darkBackground;
        };

        statusbar = {
          normal.bg = tc.background;
          normal.fg = tc.foreground;

          command.bg = tc.lightBackground;
          command.fg = tc.lightForeground;

          insert.bg = tc.green;
          insert.fg = tc.foreground;

          passthrough.bg = tc.blue;
          passthrough.fg = tc.foreground;

          private.bg = tc.magenta;
          private.fg = tc.foreground;

          progress.bg = tc.green;

          url = {
            fg = tc.green;
            hover.fg = tc.yellow;

            error.fg = tc.brightRed;
            warn.fg = tc.yellow;

            success.http.fg = tc.yellow;
            success.https.fg = tc.green;
          };
        };

        tooltip.bg = tc.tooltipBackground;
        tooltip.fg = tc.tooltipForeground;

        keyhint = {
          bg = tc.background;
          fg = tc.foreground;
          suffix.fg = tc.red;
        };

        hints = {
          bg = tc.background;
          fg = tc.foreground;
          match.fg = tc.red;
        };

        prompts = {
          bg = tc.lightBackground;
          fg = tc.lightForeground;
          border = "1px solid ${tc.lightBorder}";
          selected.bg = tc.accent;
          selected.fg = tc.foreground;
        };

        completion = {
          category = {
            bg = tc.lightBackground;
            fg = tc.lightForeground;
            border.bottom = tc.lightBackground;
            border.top = tc.lightBackground;
          };

          even.bg = tc.lightBackground;
          odd.bg = tc.lightBackground;
          fg = tc.lightForeground;

          item.selected = {
            bg = tc.accent;
            border.bottom = tc.accent;
            border.top = tc.accent;
            fg = tc.foreground;
            match.fg = tc.foreground;
          };

          scrollbar.bg = tc.lightBackground;
          scrollbar.fg = tc.darkBackground;
        };

        tabs = {
          bar.bg = tc.sidebar;
          odd.bg = tc.sidebar;
          even.bg = tc.sidebar;

          even.fg = tc.foreground;
          odd.fg = tc.foreground;
          selected = {
            even.bg = tc.accent;
            even.fg = tc.foreground;
            odd.bg = tc.accent;
            odd.fg = tc.foreground;
          };

          pinned = {
            even.bg = tc.background;
            odd.bg = tc.background;
            selected.even.bg = tc.accent;
            selected.odd.bg = tc.accent;
          };
        };

        messages = rec {
          error.bg = tc.errorBackground;
          error.fg = tc.errorForeground;
          error.border = error.bg;
          warning.bg = tc.warningBackground;
          warning.fg = tc.warningForeground;
          warning.border = warning.bg;
          info.bg = tc.infoBackground;
          info.fg = tc.infoForeground;
          info.border = info.bg;
        };

        contextmenu = {
          menu.bg = tc.menuBackground;
          menu.fg = tc.menuForeground;
          selected.bg = tc.menuSelectedBackground;
          selected.fg = tc.menuSelectedForeground;
          disabled.fg = tc.menuDisabledForeground;
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

      scrolling.bar = "always";
    };

    extraConfig = ''
      # TODO how is this done properly in programs.qutebrowser.settings?
      c.statusbar.padding = {"top": 7, "bottom": 7, "left": 4, "right": 4}
      c.tabs.padding = {"top": 7, "bottom": 6, "left": 6, "right": 6}
    '';

    # enableDefaultBindings = false;
    aliases = {
      translate = "spawn -u ${translate}";
      yank-text-anchor = "spawn -u ${yank-text-anchor}";
    };

    keyBindings = lib.mkMerge [
      {
        passthrough."<Shift+Escape>" = "mode-leave";
        normal = {
          "<Shift+Escape>" = "mode-enter passthrough";

          "zpt" = "translate {url}";
          "ya" = "yank-text-anchor";

          "ql" = "cmd-set-text -s :quickmark-load";
          "qL" = "bookmark-list";
          "qa" = "cmd-set-text -s :quickmark-add {url} \"{url:host}\"";
          "qd" = lib.mkMerge [ "cmd-set-text :quickmark-del {url:domain}" "fake-key -g <Tab>" ];

          "bl" = "cmd-set-text -s :bookmark-load";
          "bL" = "bookmark-list -j";
          "ba" = "cmd-set-text -s :bookmark-add {url} \"{title}\"";
          "bd" = lib.mkMerge [ "cmd-set-text :bookmark-del {url:domain}" "fake-key -g <Tab>" ];

          "dd" = "download";
          "dc" = "download-cancel";
          "dq" = "download-clear";
          "dD" = "download-delete";
          "do" = "download-open";
          "dr" = "download-remove";
          "dR" = "download-retry";

          "!" = "cmd-set-text :open !";
          "gss" = "cmd-set-text -s :open site:{url:domain}";

          "cnp" = ''config-cycle -p content.proxy ${lib.concatStringsSep " " proxies}'';

          ";;" = "hint all";

          # Akin to catgirl(1).
          "<Alt+Shift+Left>" = "navigate prev";
          "<Alt+Shift+Right>" = "navigate next";
          "<Alt+Shift+Up>" = "navigate strip";
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
      }
      {
        prompt."<Ctrl+y>" = null;

        normal = lib.genAttrs [
          "gd"
          "ad"
          "cd"
          "<Escape>"
          "F"
          "f"
          "gi"
          "j"
          "k"
          "q"
          "wf"
          "r"
          "d"
          "b"
          "<Ctrl+Tab>"
          "<Ctrl+Shift+Tab>"
          "q"
          "<Ctrl+q>"
          "<F11>"
        ]
          (key: null)
        ;
      }
    ];
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

          PATH="${lib.makeBinPath [ pkgs.sqlite.bin pkgs.xe ]}:$PATH"

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

  programs = {
    chromium = {
      enable = true;
      package = pkgs.ungoogled-chromium;
      dictionaries = [
        pkgs.hunspellDictsChromium.en-us
        pkgs.hunspellDictsChromium.en-gb
      ];

      extensions = [
        { id = "cjpalhdlnbpafiamejdnhcphjbkeiagm"; }
      ];
    };

    # browserpass = lib.mkIf config.programs.chromium.enable {
    #   enable = true;
    #   browsers = [ "chromium" ];
    # };
  };

  # services.xsuspender.rules =
  #   let
  #     execSuspend = builtins.toString (pkgs.writeShellScript "xsuspender-exec-suspend" ''
  #       ${lib.toShellVar "PATH" (lib.makeBinPath [ pkgs.pulseaudio pkgs.gnugrep ])}
  #       set -x
  #       # sound currently playing
  #       if pacmd list-sink-inputs | grep -q 'state: RUNNING'; then
  #           exit 1
  #       fi
  #       exit
  #     '');
  #     # [ "$(bspc query -D -n "$XID")" = "$(bspc query -D -d focused)" ]; then
  #     # window to suspend is on focused desktop, don't suspend
  #   in
  #   {
  #     qutebrowser = {
  #       matchWmClassGroupContains = "qutebrowser";
  #       suspendSubtreePattern = "QtWebEngineProcess";

  #       onlyOnBattery = true;
  #       downclockOnBattery = 0;

  #       suspendDelay = 15;
  #       resumeFor = 5;
  #       resumeEvery = 60;

  #       # inherit execSuspend;
  #     };

  #     chromium = {
  #       matchWmClassGroupContains = "chromium";
  #       suspendSubtreePattern = "chromium";

  #       onlyOnBattery = true;
  #       downclockOnBattery = 0;

  #       suspendDelay = 15;
  #       resumeFor = 5;
  #       resumeEvery = 60;

  #       inherit execSuspend;
  #     };
  #   };

  # home.packages = [
  #   pkgs.qutebrowser-sync
  #   pkgs.ffsclient
  # ];

  # services.dunst.settings.zz-qutebrowser = {
  #   desktop_entry = "org.qutebrowser.qutebrowser";
  # };
}

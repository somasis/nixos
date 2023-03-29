{ config, nixosConfig, pkgs, lib, ... }:
let
  inherit (nixosConfig.services) tor;

  translateUrl = pkgs.writeShellScript "translate-url" ''
    set -eu
    set -o pipefail

    : "''${QUTE_FIFO:?}"

    printf 'open -t -r %s\n' \
        "https://translate.google.com/translate?sl=auto&u=$(${config.programs.jq.package}/bin/jq -Rr '@uri' <<< "$1")" \
        > "''${QUTE_FIFO}"
  '';

  generateUrlTextAnchor = pkgs.writeShellScript "generate-url-text-anchor" ''
    set -eu
    set -o pipefail

    : "''${QUTE_FIFO:?}"
    : "''${QUTE_SELECTED_TEXT:?}"
    : "''${QUTE_URL:?}"

    exec >>"''${QUTE_FIFO}"

    textStart=$(
        printf '%s' "''${QUTE_SELECTED_TEXT}" \
            | sed 's/^ *//; s/ *$//' \
            | ${config.programs.jq.package}/bin/jq -Rr '@uri'
    )

    url="''${QUTE_URL%#*}#:~:text=''${textStart}"

    printf 'yank -q inline "%s" ;; message-info "Yanked URL of highlighted text to clipboard: %s"\n' "''${url}" "''${url}"
  '';
in
{
  imports = [
    ./adblock.nix
    # ./farside.nix
    ./greasemonkey.nix
    ./open.nix
    ./reader.nix
    ./search.nix
  ];

  home = {
    persistence = {
      "/persist${config.home.homeDirectory}" = {
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

      "/cache${config.home.homeDirectory}" = {
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

    sessionVariables."BROWSER" = "qutebrowser";
  };

  programs.qutebrowser = {
    enable = true;

    package = pkgs.qutebrowser.override {
      withPdfReader = false;
    };

    loadAutoconfig = true;

    settings = rec {
      # Clear default aliases
      aliases = { };

      qt.args = [
        # Force GPU-utilizing acceleration
        # <https://wiki.archlinux.org/title/Chromium#Force_GPU_acceleration>
        "ignore-gpu-blocklist"
        "enable-gpu-rasterization"
        "enable-zero-copy"

        # Enable hardware video acceleration
        # <https://wiki.archlinux.org/title/Chromium#Hardware_video_acceleration>
        # <https://community.frame.work/t/guide-linux-battery-life-tuning/6665/303>
        "enable-features=VaapiVideoDecoder,VaapiVideoEncoder"
        "enable-accelerated-mjpeg-decode"
        "enable-accelerated-video-decode"
        "disable-gpu-driver-bug-workarounds"
        "use-gl=egl"
        "disable-features=UseChromeOSDirectVideoDecoder"
      ];

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
        start_pages = "${default_page}";
      };

      # I seem to have better performance with process-per-site rather than process-per-site-instance...
      qt.chromium.process_model = "process-per-site";

      # hints.selectors["username"] = "input[type='text']:first-of-type"
      # hints.selectors['password'] = 'input[type="password"]'
      # hints.selectors["username"] = [
      #     'input[type="text"]:first-of-type',
      #     'input[type="email"]:first-of-type',
      # ]
      # hints.selectors["password"] = ['input[type="password"]']

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
        user_stylesheets = builtins.map builtins.toString [
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

      # Downloads bar.
      downloads.position = "top";
      colors.downloads.start.bg = config.xresources.properties."*darkBackground";
      colors.downloads.stop.bg = config.xresources.properties."*color2";
      colors.downloads.error.bg = config.xresources.properties."*color1";
      colors.downloads.bar.bg = config.xresources.properties."*darkBackground";

      # Statusbar.
      statusbar.position = "top";

      completion.open_categories = [
        "quickmarks"
        "searchengines"
        "bookmarks"
        "history"
        "filesystem"
      ];

      colors.statusbar.normal.bg = config.xresources.properties."*background";
      colors.statusbar.normal.fg = config.xresources.properties."*foreground";

      colors.statusbar.command.bg = config.xresources.properties."*lightBackground";
      colors.statusbar.command.fg = config.xresources.properties."*lightForeground";

      colors.statusbar.insert.bg = config.xresources.properties."*color2";
      colors.statusbar.insert.fg = config.xresources.properties."*foreground";

      colors.statusbar.passthrough.bg = config.xresources.properties."*color4";
      colors.statusbar.passthrough.fg = config.xresources.properties."*foreground";

      colors.statusbar.private.bg = config.xresources.properties."*color5";
      colors.statusbar.private.fg = config.xresources.properties."*foreground";

      colors.statusbar.progress.bg = config.xresources.properties."*color2";

      colors.statusbar.url.fg = config.xresources.properties."*color4";
      colors.statusbar.url.error.fg = config.xresources.properties."*color9";
      colors.statusbar.url.hover.fg = config.xresources.properties."*color4";
      colors.statusbar.url.success.http.fg = config.xresources.properties."*color4";
      colors.statusbar.url.success.https.fg = config.xresources.properties."*color4";
      colors.statusbar.url.warn.fg = config.xresources.properties."*color3";

      # Prompts.

      colors.prompts.bg = config.xresources.properties."*lightBackground";
      colors.prompts.fg = config.xresources.properties."*lightForeground";
      colors.prompts.border = "1px solid ${config.xresources.properties."*lightBorderColor"}";
      colors.prompts.selected.bg = config.xresources.properties."*colorAccent";
      colors.prompts.selected.fg = config.xresources.properties."*foreground";

      # Completion.

      colors.completion.category.bg = config.xresources.properties."*lightBackground";
      colors.completion.category.fg = config.xresources.properties."*lightForeground";
      colors.completion.category.border.bottom = config.xresources.properties."*lightBackground";
      colors.completion.category.border.top = config.xresources.properties."*lightBackground";
      colors.completion.even.bg = config.xresources.properties."*lightBackground";
      colors.completion.odd.bg = config.xresources.properties."*lightBackground";
      colors.completion.fg = config.xresources.properties."*lightForeground";
      colors.completion.item.selected.bg = config.xresources.properties."*colorAccent";
      colors.completion.item.selected.border.bottom = config.xresources.properties."*colorAccent";
      colors.completion.item.selected.border.top = config.xresources.properties."*colorAccent";
      colors.completion.item.selected.fg = config.xresources.properties."*foreground";
      colors.completion.item.selected.match.fg = config.xresources.properties."*foreground";
      colors.completion.scrollbar.bg = config.xresources.properties."*lightBackground";
      colors.completion.scrollbar.fg = config.xresources.properties."*darkBackground";

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

      # colors.tabs.even.fg = config.xresources.properties."*background";
      # colors.tabs.odd.fg = config.xresources.properties."*background";
      # colors.tabs.selected.even.fg = config.xresources.properties."*foreground";
      # colors.tabs.selected.odd.fg = config.xresources.properties."*foreground";
      colors.tabs.even.fg = config.xresources.properties."*foreground";
      colors.tabs.odd.fg = config.xresources.properties."*foreground";
      colors.tabs.selected.even.fg = config.xresources.properties."*foreground";
      colors.tabs.selected.odd.fg = config.xresources.properties."*foreground";

      colors.tabs.pinned.even.bg = config.xresources.properties."*background";
      colors.tabs.pinned.odd.bg = config.xresources.properties."*background";
      colors.tabs.pinned.selected.even.bg = config.xresources.properties."*colorAccent";
      colors.tabs.pinned.selected.odd.bg = config.xresources.properties."*colorAccent";
      colors.tabs.selected.even.bg = config.xresources.properties."*colorAccent";
      colors.tabs.selected.odd.bg = config.xresources.properties."*colorAccent";

      colors.messages = rec {
        error.bg = config.xresources.properties."*color1";
        warning.bg = config.xresources.properties."*color3";
        info.bg = config.xresources.properties."*colorAccent";
        info.fg = config.xresources.properties."*foreground";

        error.border = error.bg;
        warning.border = warning.bg;
        info.border = info.bg;
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
      translate = "spawn -u ${translateUrl} {url}";
      generate-text-anchor = "spawn -u ${generateUrlTextAnchor}";
    };

    keyBindings = {
      normal = {
        "zpt" = "translate";
        "ya" = "generate-text-anchor";

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

  systemd.user = {
    timers = {
      qutebrowser-vacuum = {
        Unit = {
          Description = "${config.systemd.user.services.qutebrowser-vacuum.Unit.Description} every week";
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

    services = rec {
      qutebrowser-vacuum = {
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
          ExecCondition = builtins.toString (pkgs.writeShellScript "wait-for-qutebrowser" ''
            set -eu
            set -- $(${pkgs.procps}/bin/pgrep -u "''${USER:-$(${pkgs.coreutils}/bin/id -un)}" "qutebrowser")

            [ "$#" -gt 0 ] || exit 0
            ${pkgs.extrace}/bin/pwait "$@"
          '');

          ExecStart = builtins.toString (pkgs.writeShellScript "qutebrowser-vacuum" ''
            set -eu

            PATH="${lib.makeBinPath [ pkgs.sqlite pkgs.xe ]}:$PATH"

            for db in ${lib.escapeShellArgs [ "${config.xdg.dataHome}/qutebrowser/history.sqlite" ]}; do
                sqlite3 "$db" <<'EOF'
            .timeout ${builtins.toString (60 * 1000)}
            VACUUM;
            EOF
            done
          '');

          Nice = 19;
          CPUSchedulingPolicy = "idle";
          IOSchedulingClass = "idle";
          IOSchedulingPriority = 7;
        };
      };
    };
  };
}

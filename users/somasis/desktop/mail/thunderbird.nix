{ config
, pkgs
, lib
, ...
}:
let
  tbEnable = config.programs.thunderbird.enable;
  tc = config.theme.colors;
in
{
  home.packages = lib.mkIf tbEnable [ pkgs.birdtray ];

  persist = {
    directories =
      # bindfs required because profile configs are managed by home-manager
      lib.mkIf tbEnable [{ method = "bindfs"; directory = ".thunderbird"; }]
    ;

    # files = lib.mkIf tbEnable [ "etc/birdtray-config.json" ];
  };

  xdg.configFile."birdtray-config.json" = {
    onChange = ''
      ${pkgs.systemd}/bin/systemctl --user -q is-active thunderbird.service \
          && ${pkgs.systemd}/bin/systemctl --user restart thunderbird.service \
          || :
    '';

    text =
      let
        mkIcon = icon: lib.fileContents (pkgs.runCommand "birdtray-icon.png.b64"
          { inherit icon; }
          ''
            ${pkgs.librsvg}/bin/rsvg-convert \
                --width 24 \
                --height 24 \
                --keep-aspect-ratio \
                --format png \
                "$icon" \
                | base64 -w 0 > "$out"
          ''
        );
      in
      lib.generators.toJSON { } rec {
        accounts =
          map
            (attr:
              let
                id = builtins.hashString "sha256" attr.value.name;
                profile = "${config.home.homeDirectory}/.thunderbird/default";
              in
              {
                color = config.theme.colors.accent;
                path = "${profile}/ImapMail/${id}/INBOX.msf";
              }
            )
            (lib.attrsToList config.accounts.email.accounts)
        ;

        "common/bordercolor" = "#ffffff";
        "common/borderwidth" = 0;
        "common/defaultcolor" = config.theme.colors.accent;
        "common/exitthunderbirdonquit" = true;
        "common/forceIgnoreUnreadEmailsOnMinimize" = false;
        "common/hideWhenStartedManually" = true;
        "common/hidewhenminimized" = false;
        "common/hidewhenrestarted" = true;
        "common/hidewhenstarted" = true;
        "common/ignoreShowUnreadCount" = false;
        "common/ignoreStartUnreadCount" = false;
        "common/launchthunderbird" = true;
        "common/launchthunderbirddelay" = 0;
        "common/monitorthunderbirdwindow" = false;
        "common/newemailEnabled" = false;
        "common/notificationfont" = "Sans Serif,10,-1,5,50,0,0,0,0,0";
        "common/notificationfontweight" = 50;

        "common/notificationicon" =
          mkIcon "${pkgs.papirus-icon-theme}/share/icons/Papirus/24x24/panel/indicator-messages.svg";
        "common/notificationiconunread" =
          mkIcon "${pkgs.papirus-icon-theme}/share/icons/Papirus/24x24/panel/indicator-messages-new.svg";

        "common/restartthunderbird" = true;
        "common/showDialogIfNoAccountsConfigured" = false;
        "common/showhidethunderbird" = true;
        "common/showunreademailcount" = true;
        "common/startClosedThunderbird" = true;

        "advanced/blinkingusealpha" = false;
        "advanced/forcedRereadInterval" = 0;
        "advanced/ignoreNetWMhints" = false;
        "advanced/ignoreUpdateVersion" = "";
        "advanced/notificationfontmaxsize" = 512;
        "advanced/notificationfontminsize" = 4;
        "advanced/onlyShowIconOnUnreadMessages" = false;
        "advanced/runProcessOnChange" = "";
        "advanced/tbcmdline" = [ "/usr/bin/env" "thunderbird" ];
        "advanced/tbprocessname" = "thunderbird";
        "advanced/tbwindowmatch" = "Mozilla Thunderbird";
        "advanced/unreadopacitylevel" = 1;
      };
  };

  cache.directories = lib.mkIf tbEnable [{
    method = "symlink";
    directory = config.lib.somasis.xdgCacheDir "thunderbird";
  }];

  programs.thunderbird = {
    enable = true;
    profiles.default = {
      isDefault = true;
      settings = {
        # Privacy
        "general.useragent.override" = "";
        "mailnews.headers.sendUserAgent" = false;
        "mailnews.start_page.enabled" = false;
        "network.cookie.cookieBehavior" = 3; # Only accept 3rd party cookies from visited sites
        "network.proxy.socks_remote_dns" = true;
        "datareporting.healthreport.uploadEnabled" = false;

        # Locale
        "intl.date_time.pattern_override.connector_short" = "{1} {0}";
        "intl.date_time.pattern_override.date_short" = "yyyy-MM-dd";
        "intl.date_time.pattern_override.time_short" = "hh:mm aa";
        "calendar.week.start" = 1; # Monday

        # Descending (date) sort by default
        "mailnews.default_sort_order" = 2;

        # I know what I'm doing
        "general.warnOnAboutConfig" = false;

        # Integrate with system
        "browser.display.use_document_fonts" = 0; # Don't allow messages to use non-default fonts.
        "browser.download.dir" = config.xdg.userDirs.download;
        "browser.download.downloadDir" = config.xdg.userDirs.download;
        "calendar.timezone.useSystemTimezone" = true;
        "general.smoothScroll" = false;
        "mail.tabs.drawInTitlebar" = false; # Use system titlebar
        "mousewheel.min_line_scroll_amount" = 2;
        "msgcompose.font_size" = 4;
        "pdfjs.disabled" = true;
        "toolkit.scrollbox.smoothScroll" = false;
        "ui.prefersReducedMotion" = 1;
        "widget.gtk.native-context-menus" = true;
        "widget.gtk.overlay-scrollbars.enabled" = true;
        "widget.gtk.theme-scrollbar-colors.enabled" = false;

        "mail.tabs.tabMinWidth" = 260; # Align tab with settings sidebar
        "mail.tabs.tabMaxWidth" = 260;

        # Calm notifications
        "calendar.alarms.playsound" = false;
        "calendar.alarms.showmissed" = false;
        "mail.biff.play_sound" = false;

        # Calendar settings
        "calendar.task.defaultdue" = "offsetnexthour";

        # Composition
        "mail.SpellCheckBeforeSend" = true;
        "mail.compose.autosaveinterval" = 2;

        # Enable userChrome
        "toolkit.legacyUserProfileCustomizations.stylesheets" = true;
      };

      userChrome =
        let
          modulateColor = colorName: color:
            map
              (intensity:
                let
                  amount =
                    if intensity == 50 then
                      0.0
                    else
                      if (intensity - 50) == 0 then
                        0.0
                      else if (intensity - 50) < 0 then
                        ((intensity - 50) / -1) * .01
                      else
                        (intensity - 50) * .01
                  ;

                  modulatedColor =
                    if intensity == 50 then
                      color
                    else if intensity > 50 then
                      config.lib.somasis.colors.saturate amount color
                    else # if intensity < 50
                      config.lib.somasis.colors.desaturate amount color
                  ;

                  paddedIntensity = number:
                    if (builtins.stringLength "${toString number}") >= 3 then
                      toString number
                    else
                      lib.fixedWidthString 2 "0" (toString number)
                  ;
                in
                "--color-${colorName}-${paddedIntensity intensity}: ${config.lib.somasis.colors.format ''hex'' modulatedColor} !important; /* tc.${colorName} */"
              )
              [ 05 10 15 20 25 30 35 40 45 50 55 60 65 70 75 80 85 90 95 100 ]
          ;
        in
        ''
          * {
            /* Disable animations */
            transition: none !important;

            /* Square everything */
            border-radius: 0 !important;

            /* No shadows */
            box-shadow: none !imporatnt;
          }

          :host, :root {
            /* Disable animations */
            --transition-duration: 0 !important;

            --system-color-accent: ${tc.accent} !important; /* tc.accent */
            --system-color-accent-hover: ${tc.accent} !important; /* tc.accent */
            --system-color-accent-active: ${tc.accent} !important; /* tc.accent */
            --color-accent-primary: ${tc.accent} !important; /* tc.accent */
            --color-accent-primary-hover: ${tc.accent} !important; /* tc.accent */
            --color-accent-primary-active: ${tc.accent} !important; /* tc.accent */

            /* Reset colors to fit with my theme */
            --primary: ${tc.accent} !important; /* tc.accent */
            --treeitem-background-active: ${tc.accent} !important; /* tc.accent */
            --button-active-text-color: #ffffff !important;
            --button-active-background-color: ${tc.accent} !important; /* tc.accent */
            --button-primary-active-background-color: ${tc.accent} !important; /* tc.accent */

            --button-pressed-shadow: none;

            --listbox-hover: var(--tree-view-bg);
            --treeitem-background-hover: var(--tree-view-bg);

            --listbox-selected-bg: ${tc.accent} !important; /* tc.accent */
            --listbox-focused-selected-bg: ${tc.accent} !important; /* tc.accent */
            --selected-item-color: ${tc.accent} !important; /* tc.accent */
            --selected-item-text-color: #ffffff !important;

            --toolbar-button-hover-background-color: initial;
            --toolbar-button-hover-border-color: initial;
            --toolbar-button-hover-checked-color: initial;
            --toolbarbutton-hover-background: initial;
            --toolbarbutton-hover-bordercolor: initial;
            --toolbar-button-active-background-color: ${tc.accent}; /* tc.accent */
            --toolbar-button-active-border-color: ${tc.accent}; /* tc.accent */
            --toolbarbutton-active-background: ${tc.accent}; /* tc.accent */
            --toolbarbutton-active-bordercolor: ${tc.accent}; /* tc.accent */
            --toolbarbutton-checked-background: ${tc.accent}; /* tc.accent */
            --toolbarbutton-hover-boxshadow: none;

            --menu-color: ${tc.menuForeground}; /* tc.menuForeground */
            --menu-border-color: ${tc.menuBorder}; /* tc.menuBorder */
            --menu-background-color: ${tc.menuBackground}; /* tc.menuBackground */
            --menu-item-padding: 0px;
            --menu-item-margin: 0px;

            ${lib.concatLines (
              modulateColor "red" tc.red
              ++ modulateColor "green" tc.green
              ++ modulateColor "orange" tc.yellow
              ++ modulateColor "yellow" tc.brightYellow
              ++ modulateColor "teal" tc.cyan
              ++ modulateColor "amber" tc.brightRed
              ++ modulateColor "blue" tc.blue
              ++ modulateColor "purple" tc.magenta
              ++ modulateColor "magenta" tc.brightMagenta
              ++ modulateColor "brown" tc.black
              ++ modulateColor "white" tc.white
            )}

            --color-blue-70: ${tc.accent} !important; /* tc.accent */
          }

          #folderPaneWriteMessage, #folderPaneWriteMessage:hover /* New message button */
          {
            background-color: ${tc.accent} !important; /* tc.accent */
          }

          /* Message list */

          /* Use correct foreground color on selected messages */
          [is="tree-view-table-body"] > .selected {
            color: var(--selected-item-text-color);
          }

          /* Use Arc's style for toolbars */
          #titlebar,
          #toolbar-menubar,
          unified-toolbar
          {
            background-color: ${tc.background} !important; /* tc.background */
            color: ${tc.foreground} !important; /* tc.foreground */
          }

          menubar > menu[open] {
            border-color: ${tc.accent} !important; /* tc.accent */
            background-color: ${tc.accent} !important; /* tc.accent */
            color: #ffffff !important;
          }

          unified-toolbar {
            border-bottom: 0px !important;
          }

          .spaces-toolbar:not([hidden]) {
            border-inline: none !important;
            background-image: none !important;
          }
        '';

      # .button,
      # .button:not([disabled="true"],
      # .button:enabled:is([aria-pressed="true"]) {
      #   color: var(--button-active-text-color) !important;
      #   background-color: var(--toolbar-button-active-background-color) !important;
      #   border-color: var(--toolbar-button-active-border-color) !important;
      # }

      # .button.toolbar-button,
      # .button.toolbar-button:active,
      # .button.toolbar-button:hover:active,
      # .button.unified-toolbar-button,
      # .button.unified-toolbar-button:active,
      # .button.unified-toolbar-button:hover:active,
      # toolbarbutton:active,
      # toolbarbutton:hover:active
      # {
      #   color: #ffffff;
      #   background-color: ${tc.accent}; /* tc.accent */
      # }
      #
      # /* Don't dim window contents when inactive */
      # :-moz-window-inactive {
      #   opacity: 1 !important;
      # }
    };
  };

  systemd.user.services.thunderbird = lib.mkIf tbEnable {
    Unit.Description = pkgs.birdtray.meta.description;
    Install.WantedBy = [ "graphical-session.target" ];
    Unit.PartOf = [ "graphical-session.target" ];

    Service.Type = "simple";
    Service.ExecStart = lib.getExe pkgs.birdtray;
  };

  xsession.windowManager.bspwm.rules."thunderbird:Mail:*".locked = lib.mkIf tbEnable true;
}

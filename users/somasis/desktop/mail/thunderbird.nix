{ config
, pkgs
, lib
, ...
}:
let
  tbEnable = config.programs.thunderbird.enable;
  tc = config.theme.colors;

  tbWindow = {
    class = "thunderbird";
    className = "Mail";
    role = "3pane";
  };
in
{
  persist = {
    directories =
      # bindfs required because profile configs are managed by home-manager
      lib.mkIf tbEnable [{ method = "bindfs"; directory = ".thunderbird"; }]
    ;
  };

  cache.directories = lib.mkIf tbEnable [{
    method = "symlink";
    directory = config.lib.somasis.xdgCacheDir "thunderbird";
  }];

  programs.thunderbird = {
    enable = true;
    profiles.default = rec {
      isDefault = true;

      withExternalGnupg = config.programs.gpg.enable;

      settings = {
        # Use maildir for new account storage
        "mail.serverDefaultStoreContractID" = "@mozilla.org/msgstore/maildirstore;1";

        # Privacy
        "general.useragent.override" = "";
        "mailnews.headers.sendUserAgent" = false;
        "mailnews.start_page.enabled" = false;
        "network.cookie.cookieBehavior" = 3; # Only accept 3rd party cookies from visited sites
        "network.proxy.socks_remote_dns" = true;
        "datareporting.healthreport.uploadEnabled" = false;
        "geo.enabled" = false;

        # Encryption
        "mail.e2ee.auto_enable" = true;
        "mail.openpgp.fetch_pubkeys_from_gnupg" = withExternalGnupg;

        # Locale
        "intl.date_time.pattern_override.connector_short" = "{1} {0}";
        "intl.date_time.pattern_override.date_short" = "yyyy-MM-dd";
        "intl.date_time.pattern_override.time_short" = "hh:mm aa";
        "calendar.week.start" = 1; # Monday

        # Descending (date) sort by default
        "mailnews.default_sort_order" = 2;

        # I know what I'm doing
        "general.warnOnAboutConfig" = false;
        "mail.phishing.detection.enabled" = false;
        "offline.autoDetect" = false;

        # performance?
        "mail.tabs.loadInBackground" = true;
        "browser.tabs.loadDivertedInBackground" = true;

        # Integrate with system
        "browser.download.dir" = config.xdg.userDirs.download;
        "browser.download.downloadDir" = config.xdg.userDirs.download;
        "calendar.timezone.useSystemTimezone" = true;
        "ui.use_activity_cursor" = true;
        "mail.minimizeToTray" = true;
        "general.smoothScroll" = false;
        "mail.tabs.drawInTitlebar" = false; # Use system titlebar
        "mousewheel.min_line_scroll_amount" = 2;
        "font.size.monospace.x-western" = 13;
        "font.size.variable.x-western" = 14;
        "browser.display.use_document_fonts" = 0; # Don't allow messages to use non-default fonts.
        "msgcompose.font_size" = 4;
        "pdfjs.disabled" = true;
        "toolkit.scrollbox.smoothScroll" = false;
        "ui.prefersReducedMotion" = 1;
        "widget.gtk.native-context-menus" = true;
        "mousewheel.system_scroll_override.enabled" = false;
        "widget.gtk.overlay-scrollbars.enabled" = false;
        "mail.display_glyph" = false; # don't turn emoticons into emojis
        "widget.gtk.theme-scrollbar-colors.enabled" = false;
        "mail.openMessageBehavior" = 0; # Open messages in new windows instead of tabs

        "mail.tabs.tabMinWidth" = 260; # Align tab with settings sidebar
        "mail.tabs.tabMaxWidth" = 260;

        # Calm notifications
        "calendar.alarms.playsound" = false;
        "calendar.alarms.showmissed" = false;
        "mail.biff.play_sound" = false;
        "mail.chat.play_sound" = false;


        # Calendar settings
        "calendar.task.defaultdue" = "offsetnexthour";

        # Composition
        "mail.SpellCheckBeforeSend" = false;
        "mail.compose.autosaveinterval" = 1;

        # Enable userChrome
        "toolkit.legacyUserProfileCustomizations.stylesheets" = true;
      };

      userChrome = lib.fileContents (pkgs.runCommandLocal "userChrome.css"
        {
          css =
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
                box-shadow: none !important;
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
                --color-accent-primary: ${tc.accent} !important; /* tc.accent */
                --color-accent-primary-hover: ${tc.accent} !important; /* tc.accent */
                --color-accent-primary-active: ${tc.accent} !important; /* tc.accent */

                --button-pressed-shadow: none !important;
                --button-pressed-indicator-shadow: none !important;

                --button-border-color: ${tc.lightBorder} !important;
                --button-border-size: 1px !important;
                --button-background-color: #fbfbfc !important;
                --button-text-color: #5c616c !important;

                --button-background-color-hover: ${tc.accent} !important; /* tc.accent */
                --button-hover-background-color: #ffffff !important;
                --button-hover-text-color: #5c616c !important;

                --button-active-background-color: ${tc.accent} !important; /* tc.accent */
                --button-active-text-color: #ffffff !important;
                --button-background-color-active: ${tc.accent} !important; /* tc.accent */

                --button-primary-active-background-color: ${tc.accent} !important; /* tc.accent */

                --listbox-hover: #ffffff !important;
                --treeitem-background-hover: #ffffff !important;
                --treeitem-background-selected: ${tc.accent} !important; /* tc.accent */
                --treeitem-background-active: ${tc.accent} !important; /* tc.accent */

                --listbox-selected-bg: ${tc.accent} !important; /* tc.accent */
                --listbox-focused-selected-bg: ${tc.accent} !important; /* tc.accent */
                --selected-item-color: ${tc.accent} !important; /* tc.accent */

                --selected-item-text-color: #ffffff !important;
                --new-folder-color: #ffffff !important;
                --treeitem-text-active: #ffffff !important;

                --toolbar-button-hover-background-color: initial !important;
                --toolbar-button-hover-border-color: initial !important;
                --toolbar-button-hover-checked-color: initial !important;
                --toolbarbutton-hover-background: initial !important;
                --toolbarbutton-hover-bordercolor: initial !important;
                --toolbar-button-active-background-color: ${tc.accent} !important; /* tc.accent */
                --toolbar-button-active-border-color: ${tc.accent} !important; /* tc.accent */
                --toolbarbutton-active-background: ${tc.accent} !important; /* tc.accent */
                --toolbarbutton-active-bordercolor: ${tc.accent} !important; /* tc.accent */
                --toolbarbutton-checked-background: ${tc.accent} !important; /* tc.accent */
                --toolbarbutton-hover-boxshadow: none !important;

                --menu-color: ${tc.menuForeground} !important; /* tc.menuForeground */
                --menu-border-color: ${tc.menuBorder} !important; /* tc.menuBorder */
                --menu-background-color: ${tc.menuBackground} !important; /* tc.menuBackground */

                --sidebar-background-color: #ffffff !important;
                --foldertree-background: #ffffff !important;
                --layout-background-1: #f5f6f7 !important;
                --splitter-color: #dcdfe3 !important;

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

              /* Don't dim window contents when inactive */
              :-moz-window-inactive {
                opacity: 1 !important;
                color: revert !important;
              }

              /* Menubar */
              /* Move menubar to the top of the window */
              #toolbar-menubar {
                  order: -1 !important;
              }

              .button-appmenu { display: none !important; }

              /* Folder list */

              /* Folder list > header toolbar */
              #folderPaneWriteMessage,
              #folderPaneWriteMessage:hover /* New message button */
              {
                background-color: ${tc.accent} !important; /* tc.accent */
              }

              /* Folder list > list items */

              .container {
                margin-inline: 0 !important;
              }

              /* Message list */

              /* Use correct foreground color on selected messages */
              [is="tree-view-table-body"] > .selected {
                color: var(--selected-item-text-color);
              }

              /* Message list > Quick filter bar */

              .button.check-button::before {
                display: none !important;
              }

              /* Use Arc's style for toolbars */
              #titlebar,
              #toolbar-menubar,
              unified-toolbar,
              #tabs-toolbar
              /* #quick-filter-bar, */
              /* #folderPaneHeaderBar */
              {
                background: ${tc.background} !important; /* tc.background */
                color: ${tc.foreground} !important; /* tc.foreground */
                box-shadow: none !important;
              }

              #unifiedToolbar > toolbarbutton#spacesPinnedButton,
              #status-bar > #spacesToolbarReveal {
                display: none !important;
              }

              #tabs-toolbar {
                padding-inline: 0px !important;
                padding-top: 0px !important;
              }

              .tab-line[selected="true"] {
                background-color: transparent !important;
              }

              .tab-content {
                padding-inline: 8px;
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

              /* Message view */

              /* Message view > thread preview */
              .header-buttons-container toolbarbutton {
                border-radius: 0 !important;
              }

              /* Message view > message notifications (remote content warnings, etc...) */
              /* Disable box-shadow on remote content blocking notifications */
              .container.infobar {
                box-shadow: none !important;
              }

              /* Message view > message notifications (remote content warnings, etc...) */
              /* Remove margins */
              :host([message-bar-type="infobar"]) {
                margin: 0 !important;
              }

              /* Message view > message notifications > remote content warning */
              /* Make them stand out less as they're rarely necessary to act on */
              :host([value="remoteContent"]) {
                --message-bar-background-color: var(--layout-background-1);
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
        } ''
        ${pkgs.nodePackages.prettier}/bin/prettier --stdin-filepath userChrome.css <<<"$css" > "$out"
      ''
      );
    };
  };

  systemd.user = lib.mkIf tbEnable {
    services.picom.Service.ExecStopPost = [
      "${pkgs.systemd}/bin/systemctl --user try-restart thunderbird.service"
    ];

    services.thunderbird = {
      Unit = {
        Description = config.programs.thunderbird.package.meta.description;
        PartOf = [ "graphical-session-autostart.target" ];
        Conflicts = [ "game.target" ];
        After = [ "game.target" ];
      };
      Install.WantedBy = [ "graphical-session-autostart.target" ];

      Service =
        (config.lib.somasis.makeXorgApplicationService
          (lib.getExe config.programs.thunderbird.package)
          tbWindow
        ) // { SyslogIdentifier = "thunderbird"; }
      ;
    };
  };

  xsession.windowManager.bspwm.rules."${tbWindow.class}:${tbWindow.className}:*".locked = true;
}

{ config
, osConfig
, lib
, pkgs
, ...
}:
let
  dmenu-session = pkgs.dmenu-session.override {
    dmenu = config.programs.dmenu.package;
    bspwm = config.xsession.windowManager.bspwm.package;
  };

  xres = config.xresources.properties;
in
{
  programs = {
    dmenu = {
      enable = true;

      overrides = {
        enableCaretWidth = true;
        enableColorEmoji = true;
        enableCtrlVToPaste = true;
        enableGrid = true;
        enableGridNav = true;
        enableHighlight = true;
        enableInitialText = true;
        enableInstant = true;
        enableLineHeight = true;
        enableMouseSupport = true;
        enableNoSort = true;
        enablePango = true;
        enablePlainPrompt = true;
        enablePassword = true;
        enablePrefixMatching = true;
        # enableVertFull = true;
        enableWMType = true;

        enableNumbers = true;

        enableManaged = true;
        enableXyw = true;
      };

      settings = {
        lineHeight = 48;
        caretWidth = 3;

        font = "monospace 10";

        background = config.theme.colors.darkBackground;
        foreground = config.theme.colors.darkForeground;
        backgroundSelected = config.theme.colors.accent;
        foregroundSelected = config.theme.colors.darkForeground;
        backgroundHighlight = config.theme.colors.darkBackground;
        foregroundHighlight = config.theme.colors.red;
        backgroundHighlightSelected = config.theme.colors.accent;
        foregroundHighlightSelected = config.theme.colors.red;
      };
    };

    dmenu-run = {
      enable = true;

      settings = {
        DMENU = "dmenu -x -g 4 -l 16 -S -p 'run'";

        DMENU_RUN_HISTORY = "${config.xdg.cacheHome}/dmenu-run/history";

        DMENU_RUN_SCRIPT = pkgs.writeShellScript "dmenu-run-script" (
          let
            aliases = lib.concatLines (
              lib.mapAttrsToList (n: v: ''alias ${lib.escapeShellArg n}=${lib.escapeShellArg v}'')
                (config.home.shellAliases // config.programs.bash.shellAliases)
            );

            paths = lib.optionalString (config.home.sessionPath != [ ]) ''
              PATH=${lib.concatStringsSep ":" config.home.sessionPath}"''${PATH:+:$PATH}"
            '';
          in
          ''
            ${paths}
            ${aliases}
            eval "$(wineprefix print-aliases)"

            command_not_found_handle() { , "$@"; }
          ''
        );
      };
    };

    dmenu-emoji = {
      enable = true;
      settings.DMENU = ''dmenu -fn "sans 20px" -l 8 -g 8 -S -i'';
    };
  };

  home.packages =
    lib.optional config.xsession.windowManager.bspwm.enable dmenu-session
  ;


  cache.directories = [
    { method = "symlink"; directory = config.lib.somasis.xdgCacheDir "dmenu-run"; }
    { method = "symlink"; directory = config.lib.somasis.xdgCacheDir "dmenu-emoji"; }
  ];

  services.sxhkd.keybindings =
    let
      dmenu-run = ''systemd-cat -t "dmenu-run" --level-prefix=false -- dmenu-run'';
    in
    {
      "super + grave" = dmenu-run;
      "super + Return" = dmenu-run;
      "alt + F2" = dmenu-run;
    } // lib.optionalAttrs config.xsession.windowManager.bspwm.enable {
      "super + Escape" = ''
        DMENU_SESSION_ENABLE_LOCKING=${lib.boolToString config.services.screen-locker.enable} \
            dmenu-session
      '';
    } // lib.optionalAttrs (osConfig.fonts.fontconfig.defaultFonts.emoji != [ ]) {
      "super + e" = "dmenu-emoji -c";
    } // lib.optionalAttrs config.programs.password-store.enable (
      let
        sxhkd-dmenu-pass = pkgs.writeShellScript "sxhkd-dmenu-pass" ''
          PATH=${lib.makeBinPath [ pkgs.xdotool pkgs.coreutils pkgs.findutils ]}"''${PATH:+:$PATH}"

          if appname=$(xdotool getactivewindow getwindowclassname); then
              appname=''${appname/^\.+/}
              appname=''${appname%%-*}

              appname_matches=$(
                  find -L \
                      ${lib.escapeShellArg config.programs.password-store.settings.PASSWORD_STORE_DIR} \
                      -type f \
                      -ipath "*/$appname*" \
                      | wc -l
              )

              if [ "$appname_matches" -eq 0 ]; then
                  appname=
              fi
          fi

          exec dmenu-pass ''${appname:+-i "''${appname}"} -cn "$@"
        '';
      in
      {
        # "super + shift + p" was previously used, but that's used
        # for the display settings key on the Framework keyboard
        "super + k" = sxhkd-dmenu-pass;
        "super + shift + k" = "${sxhkd-dmenu-pass} -m otp";
      }
    );

  # Use -n (instant) so that it doesn't require two clicks for one action.
  services.dunst.settings.global.dmenu = "dmenu -n -p 'notification'";
}

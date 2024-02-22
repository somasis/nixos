{ config
, osConfig
, lib
, pkgs
, ...
}:
let
  dmenu = config.programs.dmenu.package;

  bspwm = config.xsession.windowManager.bspwm.package;
  pass = config.programs.password-store.package;

  dmenu-run = pkgs.dmenu-run.override { inherit dmenu; };
  dmenu-emoji = pkgs.dmenu-emoji.override { inherit dmenu; };
  dmenu-session = pkgs.dmenu-session.override { inherit dmenu bspwm; };

  dmenu-pass = pkgs.dmenu-pass.override { inherit dmenu pass; };
  qute-pass = pkgs.qute-pass.override { inherit dmenu-pass pass; };

  xres = config.xresources.properties;
in
{
  programs.dmenu = {
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

  home.packages =
    [ dmenu-run ]
    ++ lib.optional config.xsession.windowManager.bspwm.enable dmenu-session
    ++ lib.optional (osConfig.fonts.fontconfig.defaultFonts.emoji != [ ]) dmenu-emoji
    ++ lib.optional config.programs.password-store.enable dmenu-pass
    ++ lib.optional (config.programs.qutebrowser.enable && config.programs.password-store.enable) qute-pass
  ;

  xdg.dataFile."dmenu/dmenu-run.sh".text =
    let
      aliases = lib.concatLines (
        lib.mapAttrsToList (n: v: ''alias ${lib.escapeShellArg n}=${lib.escapeShellArg v}'')
          (config.home.shellAliases // config.programs.bash.shellAliases)
      );

      paths = lib.optionalString (config.home.sessionPath != [ ]) ''
        PATH=${lib.escapeShellArg (lib.concatStringsSep ":" config.home.sessionPath)}"''${PATH:+:$PATH}"
      '';
    in
    ''
      ${paths}
      ${aliases}
    ''
  ;

  cache.directories = [{ method = "symlink"; directory = config.lib.somasis.xdgCacheDir "dmenu"; }];

  services.sxhkd.keybindings = {
    "super + grave" = "dmenu-run";
    "super + Return" = "dmenu-run";
    "alt + F2" = "dmenu-run";
  } // lib.optionalAttrs config.xsession.windowManager.bspwm.enable {
    "super + Escape" = ''
      DMENU_SESSION_ENABLE_LOCKING=${lib.boolToString config.services.screen-locker.enable} \
          dmenu-session
    '';
  } // lib.optionalAttrs (osConfig.fonts.fontconfig.defaultFonts.emoji != [ ]) {
    "super + e" = "dmenu-emoji -c";
  } // lib.optionalAttrs config.programs.password-store.enable {
    # "super + shift + p" was previously used, but that's used
    # for the display settings key on the Framework keyboard
    "super + k" = "dmenu-pass -cn";
    "super + shift + k" = "dmenu-pass -cn -m otp";
  };

  # Use -n (instant) so that it doesn't require two clicks for one action.
  services.dunst.settings.global.dmenu = "dmenu -n -p 'notification'";

  programs.qutebrowser = lib.optionalAttrs config.programs.password-store.enable {
    aliases."pass" = "spawn -u ${qute-pass}/bin/qute-pass";

    keyBindings.normal = {
      # Login
      "zll" = "pass -H";
      "zlL" = "pass -H -d <Enter>";
      "zlz" = "pass -H -S";

      "zlZ" = "pass -m fields";

      # Specific fills
      "zlu" = "pass -m username";
      "zle" = "pass -m email";
      "zlp" = "pass -m password";
      "zlo" = "pass -m otp";
    };
  };
}

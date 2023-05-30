{ config
, nixosConfig
, lib
, pkgs
, ...
}:
let
  dmenu = config.programs.dmenu.package;
  bspwm = config.xsession.windowManager.bspwm.package;
  pass = config.programs.password-store.package;

  dmenu-emoji = pkgs.dmenu-emoji.override { inherit dmenu; };
  dmenu-run = pkgs.dmenu-run.override { inherit dmenu; };
  dmenu-session = pkgs.dmenu-session.override {
    inherit dmenu;
    inherit bspwm;
  };
  dmenu-pass = pkgs.dmenu-pass;
  # dmenu-pass = pkgs.dmenu-pass.override {
  #   inherit dmenu;
  #   inherit pass;
  # };
  qute-pass = pkgs.qute-pass;
  # qute-pass = pkgs.qute-pass.override {
  #   inherit dmenu-pass;
  #   inherit pass;
  # };
in
{
  programs.dmenu = {
    enable = true;

    overrides = {
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
      enableVertFull = true;
      enableWMType = true;
    };

    settings = {
      lineHeight = 48;

      font = "monospace 10";

      background = config.xresources.properties."*darkBackground";
      foreground = config.xresources.properties."*darkForeground";
      backgroundSelected = config.xresources.properties."*colorAccent";
      foregroundSelected = config.xresources.properties."*darkForeground";
      backgroundHighlight = config.xresources.properties."*darkBackground";
      foregroundHighlight = config.xresources.properties."*color1";
      backgroundHighlightSelected = config.xresources.properties."*colorAccent";
      foregroundHighlightSelected = config.xresources.properties."*color1";
    };
  };

  home.packages =
    [ dmenu-run ]
    ++ lib.optional config.xsession.windowManager.bspwm.enable dmenu-session
    ++ lib.optional (nixosConfig.fonts.fontconfig.defaultFonts.emoji != [ ]) dmenu-emoji
    ++ lib.optional config.programs.password-store.enable dmenu-pass
    ++ lib.optional config.programs.qutebrowser.enable qute-pass
  ;

  cache.directories = [{ method = "symlink"; directory = "var/cache/dmenu"; }];

  services.sxhkd.keybindings =
    {
      "super + grave" = "${dmenu-run}/bin/dmenu-run";
      "super + Return" = "${dmenu-run}/bin/dmenu-run";
      "alt + F2" = "${dmenu-run}/bin/dmenu-run";
    }
    // lib.optionalAttrs config.xsession.windowManager.bspwm.enable {
      "super + Escape" =
        "DMENU_SESSION_ENABLE_LOCKING=${lib.boolToString config.services.screen-locker.enable} ${dmenu-session}/bin/dmenu-session"
      ;
    }
    // lib.optionalAttrs (nixosConfig.fonts.fontconfig.defaultFonts.emoji != [ ]) {
      "super + e" = "${dmenu-emoji}/bin/dmenu-emoji -c";
    }
    // lib.optionalAttrs config.programs.password-store.enable {
      # "super + shift + p" was previously used, but thats used
      # for the display settings key on the Framework keyboard
      "super + k" = "${dmenu-pass}/bin/dmenu-pass -cn";
      "super + shift + k" = "${dmenu-pass}/bin/dmenu-pass -cn -m otp";
    };

  services.dunst.settings.global.dmenu = "dmenu -p 'notification'";
}

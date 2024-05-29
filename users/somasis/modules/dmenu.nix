{ config
, lib
, pkgs
, ...
}:
with lib;
with types;

let
  dmenuConfig = config.programs.dmenu;
  dmenuPackage = config.programs.dmenu.package;
  dmenuSettings = config.programs.dmenu.settings;

  dmenuRunConfig = config.programs.dmenu-run;
  dmenuRunPackage = config.programs.dmenu-run.package;

  dmenuPassConfig = config.programs.dmenu-pass;
  dmenuPassPackage = config.programs.dmenu-pass.package;

  dmenuEmojiConfig = config.programs.dmenu-emoji;
  dmenuEmojiPackage = config.programs.dmenu-emoji.package;

  mkOverride = default: mkOption {
    inherit default;
    type = types.bool;
    example = !default;
  };

  mkSetting = requiredOverrideName: requiredOverride: realType: realDefault: description: mkOption {
    type = nullOr realType;
    default = if requiredOverride then realDefault else null;
    apply = x:
      if requiredOverride && x != null then
        x
      else if !requiredOverride && x != null then
        throw "programs.dmenu.overrides.${requiredOverrideName} is not enabled"
      else
        null
    ;
    description = "${description} (requires `programs.dmenu.overrides.${requiredOverrideName} = true;`)";
  };

  color = strMatching "^#([0-9A-Fa-f]{6}|[0-9A-Fa-f]{3})$";

  mkColorOption = description: mkOption {
    type = nullOr color;
    default = null;
    description = ''
      Color to be used for ${description}.
    '';
  };

  mkColorOptionRequiring = requiredOverrideName: requiriedOverride: description: mkOption {
    type = nullOr color;
    default = null;
    description = ''
      Color to be used for ${description}.
    '';
  };

  makeDmenuPackage = prevPackage: pkgs.wrapCommand {
    package = prevPackage.override dmenuConfig.overrides;

    wrappers = [{
      prependFlags = (lib.cli.toGNUCommandLineShell { mkOptionName = k: "-${k}"; } {
        b = dmenuSettings.bottom;
        c = dmenuSettings.center;

        l = dmenuSettings.lines;
        g = dmenuSettings.columns;
        h = dmenuSettings.lineHeight;

        X = dmenuSettings.xOffset;
        Y = dmenuSettings.yOffset;
        W = dmenuSettings.width;
        bw = dmenuSettings.borderWidth;

        fn = dmenuSettings.font;

        o = dmenuSettings.opacity;

        nb = dmenuSettings.background;
        nf = dmenuSettings.foreground;

        sb = dmenuSettings.backgroundSelected;
        sf = dmenuSettings.foregroundSelected;

        hb = dmenuSettings.backgroundHighPriority;
        hf = dmenuSettings.foregroundHighPriority;

        nhb = dmenuSettings.backgroundHighlight;
        nhf = dmenuSettings.foregroundHighlight;
        shb = dmenuSettings.backgroundHighlightSelected;
        shf = dmenuSettings.foregroundHighlightSelected;

        F = dmenuSettings.fuzzyMatching;
        x = dmenuSettings.prefixMatching;

        cw = dmenuSettings.caretWidth;
      }) + dmenuConfig.extraArgs
      ;
    }];
  };
in
{
  options.programs = {
    dmenu = {
      enable = mkEnableOption "dmenu";

      package = mkOption {
        type = types.package;
        default = pkgs.dmenu;
        description = "The package to use for dmenu. It must provide a /bin/dmenu binary.";

        apply = x: makeDmenuPackage x;
      };

      overrides = {
        enableAlpha = mkOverride false;
        enableBarPadding = mkOverride false;
        enableBorder = mkOverride false;
        enableCaretWidth = mkOverride false;
        enableCaseInsensitive = mkOverride false;
        enableCenter = mkOverride false;
        enableColorEmoji = mkOverride true;
        enableCtrlVToPaste = mkOverride true;
        enableDynamicOptions = mkOverride false;
        enableEmojiHighlight = mkOverride false;
        enableFuzzyHighlight = mkOverride false;
        enableFuzzyMatching = mkOverride false;
        enableFzfExpect = mkOverride false;
        enableGrid = mkOverride true;
        enableGridNav = mkOverride true;
        enableHighPriority = mkOverride false;
        enableHighlight = mkOverride true;
        enableIncremental = mkOverride false;
        enableInitialText = mkOverride true;
        enableInstant = mkOverride true;
        enableLineHeight = mkOverride true;
        enableManaged = mkOverride false;
        enableMoreColor = mkOverride false;
        enableMouseSupport = mkOverride true;
        enableMultiSelection = mkOverride false;
        enableNavHistory = mkOverride false;
        enableNoSort = mkOverride true;
        enableNonBlockingStdin = mkOverride false;
        enableNumbers = mkOverride false;
        enablePango = mkOverride true;
        enablePassword = mkOverride false;
        enablePipeOut = mkOverride false;
        enablePlainPrompt = mkOverride true;
        enablePrefixMatching = mkOverride false;
        enablePreselect = mkOverride false;
        enablePrintIndex = mkOverride false;
        enablePrintInputText = mkOverride false;
        enableRejectNoMatch = mkOverride false;
        enableRelativeInputWidth = mkOverride false;
        enableRestrictReturn = mkOverride false;
        enableScroll = mkOverride false;
        enableSeparator = mkOverride false;
        enableSymbols = mkOverride false;
        enableTsv = mkOverride false;
        enableVertFull = mkOverride true;
        enableWMType = mkOverride true;
        enableXresources = mkOverride false;
        enableXyw = mkOverride false;
      };

      settings = {
        bottom = mkOption {
          type = bool;
          default = false;
          description = "Default to appearing at the bottom of the monitor.";
        };

        center = mkSetting "center" dmenuConfig.overrides.enableCenter bool false ''
          Default to placing the menu in the center of the monitor.
        '';

        lines = mkOption {
          type = numbers.nonnegative;
          default = 0;
          description = ''
            How many lines to use for listing items by default.
            If 0, items will be listed horizontally.
          '';
        };

        columns = mkSetting "grid" dmenuConfig.overrides.enableGrid numbers.nonnegative 0 ''
          How many columns to use for listing items in a grid by default.
          If 0, items will not be listed in a grid.
        '';

        lineHeight = mkSetting "lineHeight" dmenuConfig.overrides.enableLineHeight numbers.positive 0 ''
          How tall a line should be.
          If 0, the line height will be based on the font height.
        '';

        xOffset = mkSetting "enableXyw" dmenuConfig.overrides.enableXyw numbers.nonnegative 0 ''
          X position of the menu.
          If null, the X position will default to the left side of the monitor.
        '';

        yOffset = mkSetting "enableXyw" dmenuConfig.overrides.enableXyw numbers.nonnegative 0 ''
          Y position of the menu.
          If null, the Y position will default to the top of the monitor.
        '';

        width = mkSetting "enableXyw" dmenuConfig.overrides.enableXyw numbers.nonnegative 0 ''
          Width of the menu.
          If null, the width will default to the width of the monitor.
        '';

        borderWidth = mkSetting "enableBorder" dmenuConfig.overrides.enableBorder numbers.nonnegative 0 ''
          Width of the menu's border.
        '';

        font = mkOption {
          type = nullOr (either str (nonEmptyListOf str));
          default = if dmenuConfig.overrides.enablePango then "monospace" else null;
          description = "A single font or a list of fonts to be used by the menu.";
        };

        opacity = mkSetting "enableAlpha" dmenuConfig.overrides.enableAlpha (numbers.between 0 1) 0 ''
          Opacity of the menu background.
        '';

        background = mkColorOption "menu background";
        foreground = mkColorOption "menu foreground";
        backgroundSelected = mkColorOption "background of selected items";
        foregroundSelected = mkColorOption "foreground of selected items";

        backgroundHighPriority = mkColorOptionRequiring "highPriority" dmenuConfig.overrides.enableHighPriority "background of high priority items";
        foregroundHighPriority = mkColorOptionRequiring "highPriority" dmenuConfig.overrides.enableHighPriority "foreground of high priority items";

        backgroundHighlight = mkColorOptionRequiring "highlight" dmenuConfig.overrides.enableHighlight "background of highlighted items";
        foregroundHighlight = mkColorOptionRequiring "highlight" dmenuConfig.overrides.enableHighlight "foreground of highlighted items";

        backgroundHighlightSelected = mkColorOptionRequiring "highlight" dmenuConfig.overrides.enableHighlight "background of highlighted selected items";
        foregroundHighlightSelected = mkColorOptionRequiring "highlight" dmenuConfig.overrides.enableHighlight "foreground of highlighted selected items";

        fuzzyMatching = mkSetting "fuzzyMatching" dmenuConfig.overrides.enableFuzzyMatching bool false ''
          Default to using fuzzy matching.
        '';
        prefixMatching = mkSetting "prefixMatching" dmenuConfig.overrides.enablePrefixMatching bool false ''
          Default to using prefix matching.
        '';

        caretWidth = mkSetting "enableCaretWidth" dmenuConfig.overrides.enableCaretWidth numbers.nonnegative 2 ''
          Width of the input box's caret.
        '';
      };

      extraArgs = mkOption {
        type = str;
        default = "";
        description = "Extra arguments to pass to dmenu.";
      };
    };

    dmenu-run = {
      enable = mkEnableOption "dmenu-run";

      package = mkOption {
        type = types.package;

        default = pkgs.dmenu-run;
        defaultText = literalExpression "pkgs.dmenu-run";

        apply = package: pkgs.wrapCommand {
          package = package.override { dmenu = dmenuRunConfig.dmenuPackage; };
          wrappers = [{ setEnvironmentDefault = dmenuRunConfig.settings; }];
        };

        description = ''
          The package to use for dmenu-run.
          It must provide a /bin/dmenu-run binary.

          It will be wrapped to add the values from config.programs.dmenu-run.settings to it.
        '';
      };

      dmenuPackage = mkOption {
        type = types.package;

        default = config.programs.dmenu.package or pkgs.dmenu;
        defaultText = literalExpression "config.programs.dmenu.package or pkgs.dmenu";

        description = ''
          The package that dmenu-run should use for dmenu(1).
          It must provide a /bin/dmenu binary.
        '';
      };

      settings = mkOption rec {
        type = with types; attrsOf (coercedTo (nullOr (oneOf [ str int path ])) (lib.generators.mkValueStringDefault { }) str);
        apply = lib.mergeAttrs default;

        default = {
          DMENU = "dmenu -p 'run'";
          DMENU_RUN_HISTORY = "${config.xdg.cacheHome}/dmenu-run/history";
          DMENU_RUN_HISTORY_LENGTH = "64";
        };

        example = {
          DMENU = "dmenu -p 'run'";
          DMEUN_RUN_HISTORY = "/dev/null";
          DMENU_RUN_HISTORY_LENGTH = "0";
          DMENU_RUN_SCRIPT = literalExpression ''
            pkgs.writeShellScript "dmenu-run-script" \'\'
              command_not_found_handle() { , "$@"; }
              \'\'
          '';
        };

        description = ''
          Environment variables that should be passed to dmenu-run.
        '';
      };
    };

    dmenu-pass = {
      enable = mkEnableOption "dmenu-pass";

      package = mkOption {
        type = types.package;

        default = pkgs.dmenu-pass;
        defaultText = literalExpression "pkgs.dmenu-pass";

        apply = package: pkgs.wrapCommand {
          package = package.override {
            dmenu = dmenuPassConfig.dmenuPackage;
            pass = config.programs.password-store.package;
          };
          wrappers = [{ setEnvironmentDefault = dmenuPassConfig.settings; }];
        };

        description = ''
          The package to use for dmenu-pass.
          It must provide a /bin/dmenu-pass binary.

          It will be wrapped to add the values from config.programs.dmenu-pass.settings to it,
          and to override the dmenu and pass packages used.
        '';
      };

      dmenuPackage = mkOption {
        type = types.package;

        default = config.programs.dmenu.package or pkgs.dmenu;
        defaultText = literalExpression "config.programs.dmenu.package or pkgs.dmenu";

        description = ''
          The package that dmenu-pass should use for dmenu(1).
          It must provide a /bin/dmenu binary.
        '';
      };

      settings = mkOption rec {
        type = with types; attrsOf (coercedTo (nullOr (oneOf [ str int path ])) (lib.generators.mkValueStringDefault { }) str);
        apply = lib.mergeAttrs default;

        default = {
          PASSWORD_STORE_DIR = config.programs.password-store.settings.PASSWORD_STORE_DIR;
          PASSWORD_STORE_CLIP_TIME = config.programs.password-store.settings.PASSWORD_STORE_CLIP_TIME or 45;
          DMENU = "dmenu -p 'pass'";
          DMENU_PASS_CACHE = "${config.xdg.cacheHome}/dmenu-pass";
        };

        description = ''
          Environment variables that should be passed to dmenu-pass.
        '';
      };
    };

    dmenu-emoji = {
      enable = mkEnableOption "dmenu-emoji";

      package = mkOption {
        type = types.package;

        default = pkgs.dmenu-emoji;
        defaultText = literalExpression "pkgs.dmenu-emoji";

        apply = package: pkgs.wrapCommand {
          package = package.override { dmenu = dmenuEmojiConfig.dmenuPackage; };
          wrappers = [{ setEnvironmentDefault = dmenuEmojiConfig.settings; }];
        };

        description = ''
          The package to use for dmenu-emoji.
          It must provide a /bin/dmenu-emoji binary.

          It will be wrapped to add the values from config.programs.dmenu-emoji.settings to it.
        '';
      };

      dmenuPackage = mkOption {
        type = types.package;

        default = config.programs.dmenu.package or pkgs.dmenu;
        defaultText = literalExpression "config.programs.dmenu.package or pkgs.dmenu";

        description = ''
          The package that dmenu-emoji should use for dmenu(1).
          It must provide a /bin/dmenu binary.
        '';
      };

      settings = mkOption rec {
        type = with types; attrsOf (coercedTo (nullOr (oneOf [ str int path ])) (lib.generators.mkValueStringDefault { }) str);
        apply = lib.mergeAttrs default;

        default = {
          DMENU = ''dmenu -fn "sans 20px" -l 8 -g 8'';
          DMENU_EMOJI_HISTORY = "${config.xdg.cacheHome}/dmenu-emoji/history";
        };

        description = ''
          Environment variables that should be passed to dmenu-pass.
        '';
      };
    };
  };

  config = {
    assertions = lib.optional dmenuPassConfig.enable {
      assertion = config.programs.password-store.enable;
      message = ''
        `programs.password-store.enable` must be true if programs.dmenu-pass.enable is true.
      '';
    };

    home.packages =
      lib.optional dmenuConfig.enable dmenuPackage
      ++ lib.optional dmenuRunConfig.enable dmenuRunPackage
      ++ lib.optional dmenuPassConfig.enable dmenuPassPackage
      ++ lib.optional dmenuEmojiConfig.enable dmenuEmojiPackage
    ;
  };
}

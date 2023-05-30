{ config
, lib
, pkgs
, ...
}:
with lib;
with types;

let
  opt = options.programs.dmenu;
  cfg = config.programs.dmenu;
  set = config.programs.dmenu.settings;

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
    package = prevPackage.override cfg.overrides;

    wrappers = [{
      prependFlags = (lib.cli.toGNUCommandLineShell { mkOptionName = k: "-${k}"; } {
        b = set.bottom;
        c = set.center;

        l = set.lines;
        g = set.columns;
        h = set.lineHeight;

        X = set.xOffset;
        Y = set.yOffset;
        W = set.width;
        bw = set.borderWidth;

        fn = set.font;

        o = set.opacity;

        nb = set.background;
        nf = set.foreground;

        sb = set.backgroundSelected;
        sf = set.foregroundSelected;

        hb = set.backgroundHighPriority;
        hf = set.foregroundHighPriority;

        nhb = set.backgroundHighlight;
        nhf = set.foregroundHighlight;
        shb = set.backgroundHighlightSelected;
        shf = set.foregroundHighlightSelected;

        F = set.fuzzyMatching;
        x = set.prefixMatching;
      }) + cfg.extraArgs
      ;
    }];
  };
in
{
  options.programs.dmenu = {
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

      center = mkSetting "center" cfg.overrides.enableCenter bool false ''
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

      columns = mkSetting "grid" cfg.overrides.enableGrid numbers.nonnegative 0 ''
        How many columns to use for listing items in a grid by default.
        If 0, items will not be listed in a grid.
      '';

      lineHeight = mkSetting "lineHeight" cfg.overrides.enableLineHeight numbers.positive 0 ''
        How tall a line should be.
        If 0, the line height will be based on the font height.
      '';

      xOffset = mkSetting "enableXyw" cfg.overrides.enableXyw numbers.nonnegative 0 ''
        X position of the menu.
        If null, the X position will default to the left side of the monitor.
      '';

      yOffset = mkSetting "enableXyw" cfg.overrides.enableXyw numbers.nonnegative 0 ''
        Y position of the menu.
        If null, the Y position will default to the top of the monitor.
      '';

      width = mkSetting "enableXyw" cfg.overrides.enableXyw numbers.nonnegative 0 ''
        Width of the menu.
        If null, the width will default to the width of the monitor.
      '';

      borderWidth = mkSetting "enableBorder" cfg.overrides.enableBorder numbers.nonnegative 0 ''
        Width of the menu's border.
      '';

      font = mkOption {
        type = nullOr (either str (nonEmptyListOf str));
        default = if cfg.overrides.enablePango then "monospace" else null;
        description = "A single font or a list of fonts to be used by the menu.";
      };

      opacity = mkSetting "enableAlpha" cfg.overrides.enableAlpha (numbers.between 0 1) 0 ''
        Opacity of the menu background.
      '';

      background = mkColorOption "menu background";
      foreground = mkColorOption "menu foreground";
      backgroundSelected = mkColorOption "background of selected items";
      foregroundSelected = mkColorOption "foreground of selected items";

      backgroundHighPriority = mkColorOptionRequiring "highPriority" cfg.overrides.enableHighPriority "background of high priority items";
      foregroundHighPriority = mkColorOptionRequiring "highPriority" cfg.overrides.enableHighPriority "foreground of high priority items";

      backgroundHighlight = mkColorOptionRequiring "highlight" cfg.overrides.enableHighlight "background of highlighted items";
      foregroundHighlight = mkColorOptionRequiring "highlight" cfg.overrides.enableHighlight "foreground of highlighted items";

      backgroundHighlightSelected = mkColorOptionRequiring "highlight" cfg.overrides.enableHighlight "background of highlighted selected items";
      foregroundHighlightSelected = mkColorOptionRequiring "highlight" cfg.overrides.enableHighlight "foreground of highlighted selected items";

      fuzzyMatching = mkSetting "fuzzyMatching" cfg.overrides.enableFuzzyMatching bool false ''
        Default to using fuzzy matching.
      '';
      prefixMatching = mkSetting "prefixMatching" cfg.overrides.enablePrefixMatching bool false ''
        Default to using prefix matching.
      '';
    };

    extraArgs = mkOption {
      type = str;
      default = "";
      description = "Extra arguments to pass to dmenu.";
    };
  };

  config = mkIf cfg.enable {
    home.packages = [ cfg.package ];
  };
}

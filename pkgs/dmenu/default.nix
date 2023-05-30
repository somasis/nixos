{ lib
, stdenv

, fetchFromGitHub
, makeWrapper

, xorg
, zlib
, pango
, pkg-config

, enableAlpha ? false
, enableBarPadding ? false
, enableBorder ? false
, enableCaseInsensitive ? false
, enableCenter ? false
, enableColorEmoji ? true
, enableCtrlVToPaste ? true
, enableDynamicOptions ? false
, enableEmojiHighlight ? false
, enableFuzzyHighlight ? false
, enableFuzzyMatching ? false
, enableFzfExpect ? false
, enableGrid ? true
, enableGridNav ? true
, enableHighPriority ? false
, enableHighlight ? true
, enableIncremental ? false
, enableInitialText ? true
, enableInstant ? true
, enableLineHeight ? true
, enableManaged ? false
, enableMoreColor ? false
, enableMouseSupport ? true
, enableMultiSelection ? false
, enableNavHistory ? false
, enableNoColorEmoji ? false
, enableNoSort ? true
, enableNonBlockingStdin ? false
, enableNumbers ? false
, enablePango ? true
, enablePassword ? false
, enablePipeOut ? false
, enablePlainPrompt ? true
, enablePrefixMatching ? false
, enablePreselect ? false
, enablePrintIndex ? false
, enablePrintInputText ? false
, enableRejectNoMatch ? false
, enableRelativeInputWidth ? false
, enableRestrictReturn ? false
, enableScroll ? false
, enableSeparator ? false
, enableSymbols ? false
, enableTsv ? false
, enableVertFull ? true
, enableWMType ? true
, enableXresources ? true
, enableXyw ? false
}:
let
  optionalCpp = opt: arg:
    if opt then
      "#define ${arg} 1"
    else
      "#define ${arg} 0"
  ;
in
stdenv.mkDerivation rec {
  pname = "dmenu";
  version = "unstable-2023-05-16";

  src = fetchFromGitHub {
    owner = "bakkeby";
    repo = "dmenu-flexipatch";
    rev = "9e721014cd90dd6782a088f4d8f96706711774ac";
    hash = "sha256-1GOCVdlx40B9u5q28SWWdEMvygUBynrM93Wmpj3/mWQ=";
  };

  enableParallelBuilding = true;

  buildInputs = [
    xorg.libX11
    xorg.libXinerama
    zlib
    pango
  ]
  ++ lib.optional enablePango pango
  ++ lib.optional enableAlpha xorg.libXrender
  ;

  nativeBuildInputs = [ makeWrapper pkg-config ];

  postPatch = ''
    sed -Ei -e 's!\<(dmenu|dmenu_path|stest)\>!'"$out/bin"'/&!g' dmenu_run
    sed -Ei -e 's!\<stest\>!'"$out/bin"'/&!g' dmenu_path
  '';

  configurePhase =
    let
      substituteArgs = lib.concatStringsSep " "
        ([ ''--replace "PREFIX = /usr/local" "PREFIX = $out"'' ]
          ++ [
          (lib.escapeShellArgs (
            [ ]
              ++ lib.optionals enablePango [ "--replace" "#PANGO" "PANGO" ]
              ++ lib.optionals (!enableAlpha) [ "--replace" "#XRENDER" "XRENDER" ]
          ))
        ])
      ;

      patches = ''
        ${optionalCpp enableAlpha "ALPHA_PATCH"}
        ${optionalCpp enableBarPadding "BARPADDING_PATCH"}
        ${optionalCpp enableBorder "BORDER_PATCH"}
        ${optionalCpp enableCaseInsensitive "CASEINSENSITIVE_PATCH"}
        ${optionalCpp enableCenter "CENTER_PATCH"}
        ${optionalCpp enableColorEmoji "COLOR_EMOJI_PATCH"}
        ${optionalCpp enableCtrlVToPaste "CTRL_V_TO_PASTE_PATCH"}
        ${optionalCpp enableDynamicOptions "DYNAMIC_OPTIONS_PATCH"}
        ${optionalCpp enableEmojiHighlight "EMOJI_HIGHLIGHT_PATCH"}
        ${optionalCpp enableFuzzyHighlight "FUZZYHIGHLIGHT_PATCH"}
        ${optionalCpp enableFuzzyMatching "FUZZYMATCH_PATCH"}
        ${optionalCpp enableFzfExpect "FZFEXPECT_PATCH"}
        ${optionalCpp enableGrid "GRID_PATCH"}
        ${optionalCpp enableGridNav "GRIDNAV_PATCH"}
        ${optionalCpp enableHighlight "HIGHLIGHT_PATCH"}
        ${optionalCpp enableHighPriority "HIGHPRIORITY_PATCH"}
        ${optionalCpp enableIncremental "INCREMENTAL_PATCH"}
        ${optionalCpp enableInitialText "INITIALTEXT_PATCH"}
        ${optionalCpp enableInstant "INSTANT_PATCH"}
        ${optionalCpp enableLineHeight "LINE_HEIGHT_PATCH"}
        ${optionalCpp enableManaged "MANAGED_PATCH"}
        ${optionalCpp enableMoreColor "MORECOLOR_PATCH"}
        ${optionalCpp enableMouseSupport "MOUSE_SUPPORT_PATCH"}
        ${optionalCpp enableMultiSelection "MULTI_SELECTION_PATCH"}
        ${optionalCpp enableNavHistory "NAVHISTORY_PATCH"}
        ${optionalCpp enableNoColorEmoji "NO_COLOR_EMOJI_PATCH"}
        ${optionalCpp enableNoSort "NO_SORT_PATCH"}
        ${optionalCpp enableNonBlockingStdin "NON_BLOCKING_STDIN_PATCH"}
        ${optionalCpp enableNumbers "NUMBERS_PATCH"}
        ${optionalCpp enablePango "PANGO_PATCH"}
        ${optionalCpp enablePassword "PASSWORD_PATCH"}
        ${optionalCpp enablePipeOut "PIPEOUT_PATCH"}
        ${optionalCpp enablePlainPrompt "PLAIN_PROMPT_PATCH"}
        ${optionalCpp enablePrefixMatching "PREFIXCOMPLETION_PATCH"}
        ${optionalCpp enablePreselect "PRESELECT_PATCH"}
        ${optionalCpp enablePrintIndex "PRINTINDEX_PATCH"}
        ${optionalCpp enablePrintInputText "PRINTINPUTTEXT_PATCH"}
        ${optionalCpp enableRejectNoMatch "REJECTNOMATCH_PATCH"}
        ${optionalCpp enableRelativeInputWidth "RELATIVE_INPUT_WIDTH_PATCH"}
        ${optionalCpp enableRestrictReturn "RESTRICT_RETURN_PATCH"}
        ${optionalCpp enableScroll "SCROLL_PATCH"}
        ${optionalCpp enableSeparator "SEPARATOR_PATCH"}
        ${optionalCpp enableSymbols "SYMBOLS_PATCH"}
        ${optionalCpp enableTsv "TSV_PATCH"}
        ${optionalCpp enableVertFull "VERTFULL_PATCH"}
        ${optionalCpp enableWMType "WMTYPE_PATCH"}
        ${optionalCpp enableXresources "XRESOURCES_PATCH"}
        ${optionalCpp enableXyw "XYW_PATCH"}
      '';
    in
    ''
      substituteInPlace ./config.mk ${substituteArgs}

      cat > patches.h <<'EOF'
      ${patches}
      EOF
    '';

  makeFlags = [ "CC:=$(CC)" "PKG_CONFIG:=$(PKG_CONFIG)" ];

  meta = with lib; {
    description = "A generic, highly customizable, and efficient menu for the X Window System";
    license = licenses.mit;
    maintainers = with maintainers; [ somasis ];
    platforms = platforms.all;
  };
}

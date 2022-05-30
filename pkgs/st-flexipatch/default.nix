{ lib
, stdenv
, fetchFromGitHub
, pkg-config
, fontconfig
, freetype
, harfbuzz
, libX11
, libXcursor
, libXft
, ncurses
,
}:
stdenv.mkDerivation rec {
  pname = "st-flexipatch";
  version = "0.8.5.20220306";

  src = fetchFromGitHub {
    owner = "bakkeby";
    repo = "st-flexipatch";
    rev = "51dc6ba469cf4e05496665c6a957cf4d5a5f9bf9";
    sha256 = "sha256-xVANnofzZGzDSf9CikH6VQlAWxjXrej2o271rMZZOlU=";
  };

  nativeBuildInputs = [
    pkg-config
    ncurses
  ];

  buildInputs = [
    libX11
    libXft
    libXcursor
    fontconfig
    freetype
    harfbuzz
  ];

  preConfigure = ''
    sed \
      -e "s@PREFIX = /usr/local@PREFIX = $out@g" \
      -e "s@^#LIGATURES@LIGATURES@" \
      -e "s@^#SIXEL@SIXEL@" \
      -e "s@^#XCURSOR@XCURSOR@" \
      -i config.mk

    sed -E \
      -e "/^static int borderpx / s/= .*/= 0;/" \
      -e "/^static unsigned int cursorstyle / s/= .*/= 5;/" \
      -e "/^static unsigned int blinktimeout / s/= .*/= 750;/" \
      -e "/^wchar_t \*worddelimiters / s/= .*/= L\" \`'\\\\\"\(\)\[\]\{\}\";/" \
      -e "/^int allowwindowops / s/= .*/= 1;/" \
      -e '/^static char \*font / s/= .*/= "monospace:size=11";/' \
      -e '/^static char \*font2\[\] / s/$/ "nasin-nanpa:size=11", "emoji:pixelsize=11"/' \
      config.def.h >> config.h

    cat > patches.h <<EOF
    #define ANYSIZE_NOBAR_PATCH 1
    #define BLINKING_CURSOR_PATCH 1
    #define BOLD_IS_NOT_BRIGHT_PATCH 1
    #define CLIPBOARD_PATCH 1
    #define COLUMNS_PATCH 1
    #define CSI_22_23_PATCH 1
    #define DEFAULT_CURSOR_PATCH 1
    #define DYNAMIC_CURSOR_COLOR_PATCH 1
    #define EXTERNALPIPE_PATCH 1
    #define FIXKEYBOARDINPUT_PATCH 1
    #define FONT2_PATCH 1
    #define HIDE_TERMINAL_CURSOR_PATCH 1
    #define LIGATURES_PATCH 1
    #define OPENURLONCLICK_PATCH 1
    #define SCROLLBACK_MOUSE_ALTSCREEN_PATCH 1
    #define SCROLLBACK_PATCH 1
    #define SIXEL_PATCH 1
    #define SPOILER_PATCH 1
    #define ST_EMBEDDER_PATCH 1
    #define SWAPMOUSE_PATCH 1
    #define THEMED_CURSOR_PATCH 1
    #define UNDERCURL_PATCH 1
    #define WIDE_GLYPHS_PATCH 1
    #define XRESOURCES_PATCH 1
    EOF
  '';

  # postInstall = ''
  #   mv $out/bin/st $out/bin/st-flexipatch
  # '';

  strictDeps = true;

  makeFlags = [
    "PKG_CONFIG=${stdenv.cc.targetPrefix}pkg-config"
  ];

  preInstall = ''
    export TERMINFO=$out/share/terminfo
  '';

  installFlags = [ "PREFIX=$(out)" ];

  meta = with lib; {
    homepage = "https://github.com/bakkeby/st-flexipatch";
    description = "simple terminal for X";
    license = licenses.mit;
    maintainers = with maintainers; [ somasis ];
    platforms = platforms.unix;
  };
}

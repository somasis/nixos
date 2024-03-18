{ config
, lib
, ...
}:
let
  inherit (config.lib.somasis) xdgDataDir;

  # $ curl -Lfs \
  #       -I -o /dev/null \
  #       -w '%{url_effective}' \
  #       'https://support.image-line.com/redirect/flstudio_win_installer'
  # $ curl -Lfs \
  #       'https://support.image-line.com/api.php?call=get_version_info&callback=il_get_version_info' \
  #       | minify --type text/javascript - \
  #       | grep -Eo '\{.*\}' \
  #       | jq '.prod[].pc.version'
  #
  # - install https://support.image-line.com/redirect/download_flofflinehelp_win
  #
  # - https://www.gvst.co.uk/packages.htm (64-bit)i
  # - https://chowdsp.com/products.html#tape
  # - https://chowdsp.com/products.html#byod
  # - https://chowdsp.com/products.html#matrix
  # - https://chowdsp.com/products.html#centaur
  # - https://chowdsp.com/products.html#kick
  # - https://chowdsp.com/products.html#phaser
  # - https://aberrantdsp.com/plugins/digitalis/
  # - https://github.com/LouisGorenfeld/DigitsVst
  # - https://github.com/asb2m10/dexed
  # - https://github.com/midilab/jc303
  # - https://github.com/artfwo/andes
  # - https://github.com/twoz/binaural-vst
  # - https://github.com/tesselode/cocoa-delay
  # - https://github.com/hollance/mda-plugins-juce
  # - https://github.com/vvvar/PeakEater
  # - https://github.com/bljustice/hue
  # - https://github.com/PentagramPro/OwlBass
  # - https://thewavewarden.com/pages/odin-2
  # - https://oxesoft.wordpress.com/
  # - https://github.com/sfztools/sfizz
  # - https://tunefish-synth.com/download
  # - https://www.igorski.nl/download/vstsid
  # - https://github.com/SpotlightKid/ykchorus
  # - https://zynaddsubfx.sourceforge.io/download.html
  # - https://github.com/wolf-plugins/wolf-shaper
  # - https://soundsfromsci.bandcamp.com/album/4-vsts-from-anosci
in
{
  xsession.windowManager.bspwm.rules = {
    "fl.exe".state = "tiled";
    "fl64.exe".state = "tiled";
  };

  persist.directories = [{
    method = "symlink";
    directory = xdgDataDir "flstudio";
  }];
}

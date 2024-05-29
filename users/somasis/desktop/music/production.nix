{ config
, lib
, pkgs
, ...
}:
let
  inherit (config.lib.somasis) xdgConfigDir xdgCacheDir xdgDataDir;

  anosci-vst =
    { lib
    , runCommandLocal
    , stdenvNoCC
    , curl
    , gnused
    , nix
    , pup
    , python3
    , unzip
    }:
    let inherit (python3.packages) mediafire-dl; in
    stdenvNoCC.mkDerivation rec {
      pname = "anosci-vst";
      version = "1504RC2";

      src = runCommandLocal "${pname}.zip"
        {
          url = "http://anosci.net/dbounce.php?al=anovst";
          hash = "sha256-Dur5f7MfuE2e7OqY+1tvMB/rxrwQWM4wotK/BLbX8kA=";
        } ''
        downloadPage=$(
            curl -Lfs "$url" \
                | pup 'body script text{}' \
                | sed -e '/:\/\// !d' -e 's|.*://|https://|' -e 's/\.zip.*/.zip/'
        )
        mediafire-dl "$downloadPage" || exit 1
        file=./*.zip
        actualHash=$(nix hash file "$file")

        if [[ "$actualHash" == "$expectedHash" ]]; then
            mv "$file" "$out"
        else
            exit 1
        fi
      '';

      nativeBuildInputs = [
        curl
        gnused
        nix
        pup
        mediafire-dl
        unzip
      ];

      phases = "installPhase";

      installPhase = ''
        cd $out
        unzip -qq $src
      '';

      meta = with lib; {
        homepage = "https://soundsfromsci.bandcamp.com/album/4-vsts-from-anosci";
        sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
        license = licenses.unfree;
      };
    }
  ;

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
  home.packages = [
    pkgs.audacity
    # pkgs.plugdata
  ];

  xsession.windowManager.bspwm.rules = {
    "fl.exe".state = "tiled";
    "fl64.exe".state = "tiled";
  };

  persist.directories = [
    { method = "symlink"; directory = xdgConfigDir "audacity"; }
    { method = "symlink"; directory = xdgDataDir "flstudio"; }
  ];

  cache.directories = [
    { method = "symlink"; directory = xdgCacheDir "audacity"; }
    { method = "symlink"; directory = xdgDataDir "audacity"; }
  ];

  # xdg.dataFile = {
  #   "wineprefixes/music/drive_c/Program Files/Common Files/VST3/anosci" = {
  #     directory = true;
  #     source = pkgs.callPackage anosci-vst { };
  #   };
  # };
}

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

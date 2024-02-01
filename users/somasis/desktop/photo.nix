{ lib
, config
, pkgs
, ...
}:
let
  inherit (config.lib.somasis) relativeToHome xdgCacheDir xdgConfigDir;
in
{
  xdg.userDirs.pictures = "${config.home.homeDirectory}/pictures";

  home.packages = [
    pkgs.nsxiv

    (pkgs.gimp-with-plugins.override {
      plugins = [
        pkgs.gimpPlugins.gmic
        pkgs.gimpPlugins.lqrPlugin
        pkgs.gimpPlugins.texturize
        pkgs.gimpPlugins.waveletSharpen
      ];
    })

    pkgs.darktable
    pkgs.inkscape
  ];

  persist.directories = [
    { method = "symlink"; directory = relativeToHome config.xdg.userDirs.pictures; }

    { method = "symlink"; directory = xdgConfigDir "GIMP"; }

    # G'MIC seems to recreate the directory if it is a symlink?
    { method = "bindfs"; directory = xdgConfigDir "gmic"; }

    { method = "symlink"; directory = xdgConfigDir "darktable"; }
    { method = "symlink"; directory = xdgConfigDir "inkscape"; }
  ];

  cache.directories = [
    { method = "symlink"; directory = xdgCacheDir "gimp"; }
    { method = "symlink"; directory = xdgCacheDir "gmic"; }

    { method = "symlink"; directory = xdgCacheDir "darktable"; }
    { method = "symlink"; directory = xdgCacheDir "gallery-dl"; }
  ];

  xdg.mimeApps = {
    defaultApplications = {
      "image/x-dcraw" = "darktable.desktop";
      "image/tiff" = "darktable.desktop";
      "image/svg+xml" = [ "inkscape.desktop" "nsxiv.desktop" "gimp.desktop" ];
    } // (
      lib.genAttrs [
        "image/avif"
        "image/bmp"
        "image/gif"
        "image/heif"
        "image/jp2"
        "image/jpeg"
        "image/jxl"
        "image/png"
        "image/webp"
        "image/x-portable-anymap"
        "image/x-portable-bitmap"
        "image/x-portable-graymap"
        "image/x-tga"
        "image/x-xpixmap"
      ]
        (_: [ "nsxiv.desktop" ])
    );

    associations.removed = lib.genAttrs [ "image/jpeg" "image/png" "image/tiff" ] (_: "darktable.desktop");
  };

  programs.gallery-dl = {
    enable = true;

    settings = {
      # Use cookies from qutebrowser if available
      cookies-from-browser = lib.mkIf config.programs.qutebrowser.enable
        "chromium:${config.xdg.dataHome}/qutebrowser/webengine";

      # extractor = {
      #   ytdl = {
      #     enabled = true;
      #     module = "yt_dlp";
      #   };
      # };

      # downloader = {
      #   ytdl.module = "yt_dlp";
      # };
    };
  };
}

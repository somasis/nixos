{ lib, config, pkgs, ... }: {
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
    { method = "symlink"; directory = "pictures"; }
    { method = "symlink"; directory = config.lib.somasis.xdgConfigDir "GIMP"; }
    { method = "symlink"; directory = config.lib.somasis.xdgConfigDir "darktable"; }
    { method = "symlink"; directory = config.lib.somasis.xdgConfigDir "inkscape"; }
  ];

  cache.directories = [
    { method = "symlink"; directory = config.lib.somasis.xdgCacheDir "gimp"; }
    { method = "symlink"; directory = config.lib.somasis.xdgCacheDir "darktable"; }
    { method = "symlink"; directory = config.lib.somasis.xdgCacheDir "gallery-dl"; }
  ];

  xdg.userDirs.pictures = "${config.home.homeDirectory}/pictures";

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

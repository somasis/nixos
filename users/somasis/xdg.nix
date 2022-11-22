{ config
, pkgs
, lib
, ...
}: {
  xdg = {
    enable = true;

    mimeApps.enable = true;

    configHome = "${config.home.homeDirectory}/etc";
    dataHome = "${config.home.homeDirectory}/share";
    cacheHome = "${config.home.homeDirectory}/var/cache";
    stateHome = "${config.home.homeDirectory}/var/spool";

    userDirs = {
      enable = true;
      createDirectories = false;

      templates = null;

      # Leave these disabled by default; they'll be enabled by their
      # corresponding files if necessary.
      desktop = lib.mkDefault null;
      documents = lib.mkDefault null;
      download = lib.mkDefault null;
      music = lib.mkDefault null;
      pictures = lib.mkDefault null;
      publicShare = lib.mkDefault null;
      videos = lib.mkDefault null;
    };
  };

  home.packages = [
    (pkgs.writeShellScriptBin "open" ''
      exec xdg-open "$@"
    '')
  ];

  # HACK this shouldn't be needed!
  home.file = {
    ".cache".source = config.lib.file.mkOutOfStoreSymlink config.xdg.cacheHome;
    ".config".source = config.lib.file.mkOutOfStoreSymlink config.xdg.configHome;
    ".local/bin".source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/bin";
    ".local/lib".source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/lib";
    ".local/share".source = config.lib.file.mkOutOfStoreSymlink config.xdg.dataHome;
    ".local/state".source = config.lib.file.mkOutOfStoreSymlink config.xdg.stateHome;
  };
}

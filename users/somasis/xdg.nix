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

      templates = "/var/empty";

      # Leave these disabled by default; they'll be enabled by their
      # corresponding files if necessary.
      desktop = lib.mkDefault "/var/empty";
      documents = lib.mkDefault "/var/empty";
      download = lib.mkDefault "/var/empty";
      music = lib.mkDefault "/var/empty";
      pictures = lib.mkDefault "/var/empty";
      publicShare = lib.mkDefault "/var/empty";
      videos = lib.mkDefault "/var/empty";
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

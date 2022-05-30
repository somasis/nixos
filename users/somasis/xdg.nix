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

      documents = "${config.home.homeDirectory}/study/current";
      publicShare = "${config.home.homeDirectory}/shared/public";
      templates = "/var/empty";

      # Leave these disabled by default; they'll be enabled by their
      # corresponding files if necessary.
      desktop = lib.mkDefault "/var/empty";
      download = lib.mkDefault "/var/empty";
      music = lib.mkDefault "/var/empty";
      pictures = lib.mkDefault "/var/empty";
      videos = lib.mkDefault "/var/empty";
    };
  };

  home.packages = [
    (pkgs.writeShellScriptBin "open" ''
      exec xdg-open "$@"
    '')
  ];

  home.file.".cache".source = config.lib.file.mkOutOfStoreSymlink config.xdg.cacheHome;
  home.file.".config".source = config.lib.file.mkOutOfStoreSymlink config.xdg.configHome;
  home.file.".local/bin".source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/bin";
  home.file.".local/lib".source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/lib";
  home.file.".local/share".source = config.lib.file.mkOutOfStoreSymlink config.xdg.dataHome;
  home.file.".local/state".source = config.lib.file.mkOutOfStoreSymlink config.xdg.stateHome;
}

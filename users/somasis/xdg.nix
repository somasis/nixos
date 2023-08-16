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
    stateHome = "${config.home.homeDirectory}/var/lib";

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

  # Force replacing mimeapps.list, since it might have been changed
  # during system runtime (and thus de-symlinked).
  # <https://github.com/nix-community/home-manager/issues/4199#issuecomment-1620657055>
  xdg.configFile."mimeapps.list".force = true;

  home = {
    packages = [
      (pkgs.writeShellScriptBin "open" ''
        exec xdg-open "$@"
      '')
    ];

    # HACK this shouldn't be needed!
    file = {
      ".cache".source = config.lib.file.mkOutOfStoreSymlink config.xdg.cacheHome;
      ".config".source = config.lib.file.mkOutOfStoreSymlink config.xdg.configHome;
      ".local/bin".source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/local/bin";
      ".local/share".source = config.lib.file.mkOutOfStoreSymlink config.xdg.dataHome;
      ".local/state".source = config.lib.file.mkOutOfStoreSymlink config.xdg.stateHome;
    };

    sessionVariables."W3M_DIR" = "${config.xdg.stateHome}/w3m";
  };

  cache.directories = [{
    directory = "var/lib/w3m";
    method = "symlink";
  }];
}

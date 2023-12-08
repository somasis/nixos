{ config
, pkgs
, ...
}: {
  programs.pidgin = {
    enable = true;
    plugins = [
      pkgs.pidgin-gnome-keyring
      pkgs.pidgin-groupchat-typing-notifications
      pkgs.pidgin-window-merge
      pkgs.purple-plugin-pack

      pkgs.pidgin-opensteamworks
      pkgs.pidgin-skypeweb
      pkgs.purple-discord
      pkgs.purple-facebook
      pkgs.purple-googlechat
      pkgs.purple-instagram
      pkgs.purple-matrix
      pkgs.purple-signald
      pkgs.signald
    ];
  };

  persist.directories = [
    { method = "symlink"; directory = ".purple"; }
    { method = "symlink"; directory = config.lib.somasis.xdgConfigDir "pidgin"; }
  ];
}

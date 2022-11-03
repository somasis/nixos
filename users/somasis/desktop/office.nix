{ pkgs, config, ... }: {
  home.packages = [ pkgs.libreoffice ];

  # See for more details:
  # <https://wiki.documentfoundation.org/UserProfile#User_profile_content>
  home.persistence = {
    "/persist${config.home.homeDirectory}".directories = (map (x: "etc/libreoffice/4/${x}") [
      "user/autocorr"
      "user/autotext"
      "user/basic"
      "user/config"
      "user/database"
      "user/extensions"
      "user/gallery"
      "user/template"
      "user/uno_packages"
      "user/wordbook"
    ]);

    "/cache${config.home.homeDirectory}".directories = (map (x: "etc/libreoffice/4/${x}") [
      "cache"
      "user/store"
      "user/temp"
    ]);
  };

  systemd.user.services.libreoffice = {
    Unit = {
      Description = pkgs.libreoffice.meta.description;
      # PartOf = [ "graphical-session.target" ];
    };
    # Install.WantedBy = [ "graphical-session.target" ];

    Service = {
      Type = "simple";
      ExecStart = [
        "${pkgs.libreoffice}/bin/libreoffice --quickstart --nologo"
      ];
    };
  };
}

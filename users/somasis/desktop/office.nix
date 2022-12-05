{ pkgs
, config
, ...
}: {
  home.packages = [ pkgs.libreoffice ];

  # See for more details:
  # <https://wiki.documentfoundation.org/UserProfile#User_profile_content>
  home.persistence."/persist${config.home.homeDirectory}".directories = [ "etc/libreoffice" ];

  systemd.user.services.libreoffice = {
    Unit = {
      Description = pkgs.libreoffice.meta.description;
      PartOf = [ "graphical-session.target" ];
    };
    Install.WantedBy = [ "graphical-session.target" ];

    Service = {
      Type = "simple";
      ExecStart = [
        "${pkgs.libreoffice}/bin/libreoffice --quickstart --nologo --nodefault"
      ];
      Restart = "on-success";
    };
  };
}

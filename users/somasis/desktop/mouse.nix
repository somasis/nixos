{ pkgs, ... }: {
  systemd.user.services.xbanish = {
    Unit = {
      Description = "Hide the mouse pointer when typing";
      PartOf = [ "graphical-session.target" ];
    };
    Install.WantedBy = [ "graphical-session.target" ];

    Service = {
      ExecStart = "${pkgs.xbanish}/bin/xbanish -i all";
      Restart = "always";
    };
  };
}

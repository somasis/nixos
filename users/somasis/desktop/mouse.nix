{ pkgs, ... }: {
  services.unclutter = {
    enable = true;
    timeout = 5;
    extraOptions = [ "exclude-root" "ignore-scrolling" ];
  };

  # systemd.user.services.xbanish = {
  #   Unit = {
  #     Description = "Hide the mouse pointer when typing";
  #     PartOf = [ "graphical-session.target" ];
  #   };
  #   Install.WantedBy = [ "graphical-session.target" ];

  #   Service = {
  #     ExecStart = "${pkgs.xbanish}/bin/xbanish -i all";
  #     Restart = "always";
  #   };
  # };
}

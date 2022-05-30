{ pkgs, ... }: {
  systemd.user.services.joystickwake = {
    Service.Type = "simple";
    Service.ExecStart = "${pkgs.joystickwake}/bin/joystickwake";
    Install.WantedBy = [ "graphical-session.target" ];
    Unit.PartOf = [ "graphical-session.target" ];
  };
}

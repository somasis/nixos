{ config, lib, ... }: {
  imports = [
    # ./journal.nix
    # ./wttr.nix
  ];

  services.stw.enable = lib.mkIf (config.services.stw.widgets != { }) true;

  systemd.user.targets.stw.Unit.Conflicts = [ "game.target" ];
}

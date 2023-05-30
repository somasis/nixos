{ config, lib, ... }: {
  imports = [
    # ./journal.nix
    # ./wttr.nix
  ];

  somasis.chrome.stw.enable = lib.mkIf (config.somasis.chrome.stw.widgets != { }) true;
}

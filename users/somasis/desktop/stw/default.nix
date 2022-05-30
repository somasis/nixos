{
  imports = [
    # ./journal.nix
    ./sonapona.nix
    ./wttr.nix
  ];

  systemd.user.targets.stw = {
    Unit.Description = "All stw(1) instances";
    Install.WantedBy = [ "root-windows.target" ];
    Unit.PartOf = [ "root-windows.target" ];
  };
}

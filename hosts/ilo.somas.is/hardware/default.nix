{ pkgs, ... }: {
  imports = [
    ./audio.nix
    ./autorandr.nix
    ./bluetooth.nix
    ./brightness.nix
    ./ddcci.nix
    ./fingerprint.nix
    ./fwupd.nix
    ./print.nix
    ./scan.nix
    ./sensors.nix
    ./smart.nix
    ./touchpad.nix
  ];

  # services.usbguard = {
  #   enable = true;
  #   package = pkgs.usbguard-nox;
  #   IPCAllowedGroups = [ "wheel" ];
  # };

  # environment.persistence."/cache".directories = [
  #   {
  #     directory = "/var/lib/usbguard";
  #     mode = "0775";
  #     user = "root";
  #     group = "wheel";
  #   }
  # ];

  # Fix watchdog delaying reboot
  # https://wiki.archlinux.org/title/Framework_Laptop#ACPI
  systemd.watchdog.rebootTime = "0";
}

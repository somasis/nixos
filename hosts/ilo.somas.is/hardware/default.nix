{
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

  # Fix watchdog delaying reboot
  # https://wiki.archlinux.org/title/Framework_Laptop#ACPI
  systemd.watchdog.rebootTime = "0";
}

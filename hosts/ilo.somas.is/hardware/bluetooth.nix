{ config, pkgs, ... }: {
  hardware.bluetooth = {
    enable = true;

    # Necessary for gamepad support (or at least, the 8BitDo controller I have).
    package = pkgs.bluez5-experimental;
  };

  boot.initrd.systemd.storePaths = [
    config.hardware.bluetooth.package
    pkgs.networkmanager
  ];

  # Previously disabled by hardened profile.
  # Needed for bluetooth and wifi connectivity.
  security.lockKernelModules = false;

  environment.persistence."/persist".directories = [ "/var/lib/bluetooth" ];
}

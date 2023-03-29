{ config, pkgs, ... }: {
  hardware.bluetooth = {
    enable = true;

    # Necessary for gamepad support (or at least, the 8BitDo controller I have).
    package = pkgs.bluez5-experimental;

    # hsphfpd.enable = true;

    # Report headphones' battery level to UPower
    # <https://wiki.archlinux.org/title/Bluetooth#Enabling_experimental_features>
    settings = {
      General = {
        Experimental = config.services.upower.enable;
        KernelExperimental = config.services.upower.enable;
      };
    };
  };

  # # Allow Bluetooth peripherals to wake up the system from sleep
  # # $ lsusb | grep bluetooth -i
  # # Bus 003 Device 004: ID 8087:0032 Intel Corp. AX210 Bluetooth
  # services.udev.extraRules =
  #   let
  #     wakeup = pkgs.writeShellScript "wakeup" ''
  #       set -x
  #       echo enabled > "/sys/$DEVPATH/../power/wakeup"
  #     '';
  #   in
  #   ''
  #     SUBSYSTEM=="usb". ATTRS{idVendor}=="8087", ATTRS{idProduct}=="0032" RUN+="${wakeup}"
  #   '';

  boot.initrd.systemd.storePaths = [
    config.hardware.bluetooth.package
    pkgs.networkmanager
  ];

  # Previously disabled by hardened profile.
  # Needed for bluetooth and wifi connectivity.
  security.lockKernelModules = false;

  environment.persistence."/persist".directories = [ "/var/lib/bluetooth" ];
}

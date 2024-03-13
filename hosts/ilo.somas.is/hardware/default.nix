{ pkgs
, lib
, ...
}: {
  imports = [
    ./audio.nix
    ./display.nix
    ./bluetooth.nix
    ./brightness.nix
    ./ddcci.nix
    ./fingerprint.nix
    ./phone.nix
    ./print.nix
    ./scan.nix
    ./sensors.nix
    ./smart.nix
    ./touchpad.nix
  ];

  hardware.enableRedistributableFirmware = true;
  boot = {
    initrd = {
      availableKernelModules = [ "xhci_pci" "thunderbolt" "nvme" "usb_storage" "sd_mod" ];
      kernelModules = [ "xhci_pci" "thunderbolt" "nvme" "usb_storage" "sd_mod" ];
    };

    kernelModules = [ "kvm-intel" "nvme" "xhci_pci" "thunderbolt" "usb_storage" "sd_mod" ];
  };

  # Keep system firmware up to date.
  # TODO: Framework still doesn't have their updates in LVFS properly,
  #       <https://knowledgebase.frame.work/en_us/framework-laptop-bios-releases-S1dMQt6F#:~:text=Updating%20via%20LVFS%20is%20available%20in%20the%20testing%20channel>
  services.fwupd = {
    enable = true;
    extraRemotes = [ "lvfs-testing" ];
  };

  services.usbguard = {
    enable = true;
    package = pkgs.usbguard;

    IPCAllowedGroups = [ "wheel" ];

    # Automatically allow devices.
    # We will block devices inserted while on the lock screen.
    implicitPolicyTarget = "allow";
  };

  environment.systemPackages = [
    pkgs.usbguard-notifier
    pkgs.framework-tool
  ];

  systemd = {
    packages = [ pkgs.usbguard-notifier ];
    user.services.usbguard-notifier = {
      # partOf = [ "graphical-session.target" ];
      wantedBy = [ "graphical-session.target" ];

      # Remove "usbguard.service" dependency, since it doesn't really work
      after = lib.mkForce [ ];

      # then add back the dependency through a hack since we can't really
      # declare a user service's dependency on a system service.
      # <https://github.com/systemd/systemd/issues/3312>
      preStart = ''
        ${pkgs.systemd-wait}/bin/systemd-wait -q usbguard.service active
      '';
    };
  };

  # RetroArch joysticks and stuff
  services.udev.packages = [ pkgs.game-devices-udev-rules ];
  hardware.uinput.enable = true;

  persist.directories = [ "/var/lib/fwupd" ];

  cache.directories = [
    "/var/cache/fwupd"
    { directory = "/var/lib/usbguard"; mode = "0775"; user = "root"; group = "wheel"; }
  ];

  # VDPAU, VAAPI, etc. is handled by <nixos-hardware/common/gpu/intel>,
  # which is imported by <nixos-hardware/framework>.
  hardware.opengl.driSupport32Bit = true;

  # Fix watchdog delaying reboot
  # https://wiki.archlinux.org/title/Framework_Laptop#ACPI
  systemd.watchdog.rebootTime = "0";
}

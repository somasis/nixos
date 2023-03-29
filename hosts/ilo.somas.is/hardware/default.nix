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

  hardware.enableRedistributableFirmware = true;
  boot.initrd.availableKernelModules = [ "xhci_pci" "thunderbolt" "nvme" "usb_storage" "sd_mod" ];
  boot.initrd.kernelModules = [ "xhci_pci" "thunderbolt" "nvme" "usb_storage" "sd_mod" ];
  boot.kernelModules = [ "kvm-intel" "nvme" "xhci_pci" "thunderbolt" "usb_storage" "sd_mod" ];

  # environment.systemPackages = [
  #   (pkgs.ectool.overrideAttrs (final: prev: {
  #     pname = "fw-ectool";
  #     version = "unstable-2023-01-04";

  #     src = pkgs.fetchFromGitHub {
  #       owner = "FrameworkComputer";
  #       repo = "EmbeddedController";
  #       rev = "38c1b38254793a2ed25861330ebc786daa5b48fb";
  #       hash = "sha256-m7Zb6a4azmpLxFHUdLh3mj8EmJaaCmueuJihfdtBVlc=";
  #     };

  #     makeFlags = prev.makeFlags
  #       ++ [ "BOARD=hx20" ];

  #     meta = {
  #       description = "${prev.meta.description} (for Framework laptops)";
  #       homepage = "https://github.com/FrameworkComputer/EmbeddedController";
  #     };
  #   }))
  # ];

  # services.usbguard = {
  #   enable = true;
  #   package = pkgs.usbguard;
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

  # VDPAU, VAAPI, etc. is handled by <nixos-hardware/common/gpu/intel>,
  # which is imported by <nixos-hardware/framework>.
  hardware.opengl.driSupport32Bit = true;

  # Fix watchdog delaying reboot
  # https://wiki.archlinux.org/title/Framework_Laptop#ACPI
  systemd.watchdog.rebootTime = "0";
}

{ pkgs, ... }: {
  services.logind = {
    lidSwitchExternalPower = "ignore";

    extraConfig = ''
      HandlePowerKey=suspend
      HandlePowerKeyLongPress=poweroff
      PowerKeyIgnoreInhibited=yes
    '';
  };

  # Auto-tune with powertop on boot.
  powerManagement.powertop.enable = true;
  environment.persistence."/cache".directories = [ "/var/cache/powertop" ];

  # Manage CPU temperature.
  services.thermald.enable = true;

  # Automatically `nice` programs for better performance.
  services.ananicy = {
    enable = true;

    # TODO Use the fast C++ reimplementation of ananicy.
    # package = pkgs.ananicy-cpp;
  };

  # ananicy spams the log constantly
  systemd.services.ananicy-cpp.unitConfig.StandardOutput = "null";

  powerManagement.cpuFreqGovernor = "performance";
}

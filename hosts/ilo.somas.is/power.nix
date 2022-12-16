{ pkgs, ... }:
{
  services.logind = {
    lidSwitch = "suspend";
    lidSwitchExternalPower = "ignore";

    extraConfig = ''
      HandlePowerKey=suspend
      HandlePowerKeyLongPress=poweroff
      PowerKeyIgnoreInhibited=yes
    '';
  };

  services.upower = {
    enable = true;
    criticalPowerAction = "PowerOff";

    percentageLow = 15;
    percentageCritical = 5;
    percentageAction = 0;
  };

  powerManagement.cpuFreqGovernor = "performance";

  # Auto-tune with powertop on boot.
  powerManagement.powertop.enable = true;
  environment.persistence."/cache".directories = [ "/var/cache/powertop" ];

  # Manage CPU temperature.
  services.thermald.enable = true;

  # Automatically `nice` programs for better performance.
  services.ananicy = {
    enable = true;
    package = pkgs.ananicy-cpp;
  };

  # ananicy spams the log constantly
  systemd.services.ananicy-cpp.serviceConfig.StandardOutput = "null";
}

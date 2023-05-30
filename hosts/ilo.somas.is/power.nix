{ lib, pkgs, ... }: {
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
  cache.directories = [ "/var/cache/powertop" ];
  log.directories = [ "/var/lib/upower" ];

  # Manage CPU temperature.
  services.thermald.enable = true;

  # Automatically `nice` programs for better performance.
  services.ananicy = {
    enable = true;
    package = pkgs.ananicy-cpp;
  };

  # ananicy spams the log constantly
  systemd.services.ananicy-cpp.serviceConfig.StandardOutput = "null";

  systemd.shutdown."wine-kill" = pkgs.writeShellScript "wine-kill" ''
    ${pkgs.procps}/bin/pkill '^winedevice\.exe$' || :
    if [[ -n "$(${pkgs.procps}/bin/pgrep '^winedevice\.exe$')" ]]; then
        ${pkgs.procps}/bin/pkill -e -9 '^winedevice\.exe$' || :
    fi
    exit 0
  '';

  environment.etc."systemd/system-sleep/wake-xsecurelock".source = pkgs.writeShellScript "wake-xsecurelock" ''
    if [[ "$1" = "post" ]]; then
        ${pkgs.procps}/bin/pkill -x -USR2 xsecurelock || :
    fi
    exit 0
  '';
}

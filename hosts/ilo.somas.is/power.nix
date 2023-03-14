{ lib
, pkgs
, ...
}:
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

  # Stolen from <https://github.com/ncfavier/config/blob/0c12d8559f7b2aa2ea0ddc9cb2cec5066469cabe/modules/station/default.nix>
  environment.etc."systemd/system-sleep/batenergy".source = pkgs.writeShellScript "batenergy" ''
    PATH=${lib.makeBinPath [ pkgs.coreutils pkgs.bc ]}":$PATH"
    source ${pkgs.fetchFromGitHub {
      owner = "equaeghe";
      repo = "batenergy";
      rev = "13c381f68f198af361c5bd682b32577131fbb60f";
      hash = "sha256-4JQrSD8HuBDPbBGy2b/uzDvrBUZ8+L9lAnK95rLqASk=";
    }}/batenergy.sh "$@"
  '';
}

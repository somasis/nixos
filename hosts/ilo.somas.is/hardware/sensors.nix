{ pkgs, ... }: {
  boot.kernelModules = [
    "coretemp" # Used for reading CPU temperature

    # # Used for reading RAM temperature
    # "i2c_dev"
    # "jc42"
  ];
  environment.systemPackages = [ pkgs.lm_sensors ];

  # Add sensors for RAM temperature
  # systemd.tmpfiles.rules = [ "w /sys/bus/i2c/devices/i2c-15/new_device - - - - jc42 0x44" ];
  # environment.etc."sensors.d/ram".text = ''
  #   chip "jc42-i2c-15-44"
  #     label temp1 "ram1"
  # '';
}

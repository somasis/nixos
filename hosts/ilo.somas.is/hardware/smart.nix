{ pkgs, ... }: {
  services.smartd =
    let
      smartdNotify =
        pkgs.writeShellScript "smartd-notify" ''
          ${pkgs.libnotify}/bin/notify-send -a smartd \
              -u critical \
              -i preferences-smart-status \
              "smartd: $SMARTD_DEVICEINFO"
              "$SMARTD_MESSAGE"
        '';
    in
    {
      enable = true;
      notifications.x11.enable = false;

      autodetect = false;
      defaults.monitored = "-a -o on -s (S/../.././02|L/../../7/04) -M exec ${smartdNotify}";
      devices = [{ device = "/dev/disk/by-id/nvme-WDS100T1X0E-00AFY0_2045A0800564"; }];
    };
}

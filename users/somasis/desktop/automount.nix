{ config
, osConfig
, pkgs
, ...
}:
let
  dmenu-password = pkgs.writeShellScript "dmenu-password" ''
    dmenu -p "password [$1]" -P </dev/null
  '';
in
{
  services.udiskie = {
    inherit (osConfig.services.udisks2) enable;

    automount = false;
    notify = true;
    tray = "auto";

    settings = {
      program_options = {
        menu = "flat";

        password_prompt = [ dmenu-password "{device_presentation}" ];
        password_cache = 60;
      };

      notifications.timeout = -1;
      notification_actions = {
        device_added = [ "mount" "detach" ];
        device_mounted = [ "browse" "unmount" ];
        device_unmounted = [ "mount" "detach" ];
      };
    };
  };

  home.packages = [ pkgs.udiskie ];
}

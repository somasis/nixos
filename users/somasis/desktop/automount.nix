{ nixosConfig, ... }:
assert nixosConfig.services.udisks2.enable;
{
  services.udiskie = {
    enable = true;
    tray = "never";
  };
}

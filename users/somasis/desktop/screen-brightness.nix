{ nixosConfig, config, pkgs, ... }:
assert nixosConfig.hardware.brillo.enable;
{
  home.persistence."/cache${config.home.homeDirectory}".directories = [ "var/cache/brillo" ];
  home.packages = [ pkgs.brillo ];

  # Hardware: {decrease, increase} screen backlight - fn + {f4,f5}
  services.sxhkd.keybindings."@XF86MonBrightness{Down,Up}" = ''
    ${pkgs.brillo}/bin/brillo -Ll \
        | ${pkgs.xe}/bin/xe \
            -I '!!' \
            -j0 \
            ${pkgs.brillo}/bin/brillo \
                -s !! \
                -u 100000 \
                -q \
                {-U,-A} 2
  '';
}

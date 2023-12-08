{ osConfig, config, pkgs, ... }:
assert osConfig.hardware.brillo.enable;
{
  cache.directories = [{ method = "symlink"; directory = config.lib.somasis.xdgCacheDir "brillo"; }];
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

{ lib
, config
, osConfig
, ...
}:
let
  inherit (config.lib.somasis) mkColorOption;
in
import ../theme-common.nix {
  inherit lib config;

  mkThemeColorOption =
    name:
    fallback:
    mkColorOption {
      format = "hex";
      default = osConfig.theme.colors."${name}" or fallback;
    };
}

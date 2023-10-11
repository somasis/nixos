{ lib
, config
, ...
}:
let
  inherit (config.lib.somasis) mkColorOption;
in
import ./theme-common.nix {
  inherit lib config;

  mkThemeColorOption =
    name:
    default:
    mkColorOption {
      format = "hex";
      inherit default;
    };
}

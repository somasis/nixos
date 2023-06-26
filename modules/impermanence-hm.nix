{ lib
, config
, osConfig ? { }
, ...
}:
let
  inherit (lib)
    mkAliasOptionModule
    mkOption
    types
    ;

  default = type: osConfig.impermanence."${type}" or "/${type}${config.home.homeDirectory}";
  mkPath = default: description: mkOption {
    inherit default description;
    type = types.path;
  };
in
{
  options.persistence = {
    persist = mkPath (default "persist") ''
      The system's default persist directory.
      This directory is used for more permanent data, such as what would go in
      $XDG_DATA_HOME, $XDG_STATE_HOME, or $XDG_CONFIG_HOME.
    '';
    cache = mkPath (default "cache") ''
      The system's default cache directory.
      This directory is used for less permanent data, such as what would go in
      $XDG_CACHE_HOME.
    '';
    log = mkPath (default "log") ''
      The system's default log directory.
      This directory is used for somewhat permanent data, such as what would go in
      $XDG_CACHE_HOME.
    '';
  };

  imports = [
    (mkAliasOptionModule [ "persist" ] [ "home" "persistence" config.persistence.persist ])
    (mkAliasOptionModule [ "cache" ] [ "home" "persistence" config.persistence.cache ])
    (mkAliasOptionModule [ "log" ] [ "home" "persistence" config.persistence.log ])
  ];
}

{ config, lib, pkgs, ... }:

with lib;

let
  inherit (pkgs.stdenv.hostPlatform) isDarwin;

  cfg = config.programs.zotero;

  jsonFormat = pkgs.formats.json { };

  zoteroConfigPath =
    if isDarwin then "Library/Application Support/Zotero" else ".zotero";

  profilesPath =
    if isDarwin then "${zoteroConfigPath}/Profiles" else "${zoteroConfigPath}/zotero";

  profiles = flip mapAttrs' cfg.profiles
    (_: profile:
      nameValuePair "Profile${toString profile.id}" {
        Name = profile.name;
        Path = if isDarwin then "Profiles/${profile.path}" else profile.path;
        IsRelative = 1;
        Default = if profile.isDefault then 1 else 0;
      }) // {
    General = { StartWithLastProfile = 1; };
  };

  profilesIni = generators.toINI { } profiles;

  userPrefValue = pref:
    builtins.toJSON (if isBool pref || isInt pref || isString pref then
      pref
    else
      builtins.toJSON pref);

  mkUserJs = prefs: extraPrefs:
    ''
      // Generated by Home Manager.

      ${concatStrings (mapAttrsToList (name: value: ''
        user_pref("${name}", ${userPrefValue value});
      '') prefs)}

      ${extraPrefs}
    '';
in
{
  meta.maintainers = [ maintainers.somasis ];

  options.programs.zotero = {
    enable = mkEnableOption "Zotero";

    package = mkOption {
      type = types.package;
      default = pkgs.zotero;
      defaultText = literalExpression "pkgs.zotero";
      description = "The Zotero package to use.";
    };

    profiles = mkOption {
      type = types.attrsOf (types.submodule ({ config, name, ... }: {
        options = {
          name = mkOption {
            type = types.str;
            default = name;
            description = "Profile name.";
          };

          id = mkOption {
            type = types.ints.unsigned;
            default = 0;
            description = ''
              Profile ID. This should be set to a unique number per profile.
            '';
          };

          isDefault = mkOption {
            type = types.bool;
            default = config.id == 0;
            defaultText = "true if profile ID is 0";
            description = "Whether this is a default profile.";
          };

          path = mkOption {
            type = types.str;
            default = name;
            description = "Profile path.";
          };

          settings = mkOption {
            type = types.attrsOf (jsonFormat.type // {
              description =
                "Zotero preference (int, bool, string, and also attrs, list, float as a JSON string)";
            });
            default = { };
            example = literalExpression ''
              {
                "extensions.zotero.export.citePaperJournalArticleURL" = true;
                "extensions.zotero.export.lastStyle" = "http://www.zotero.org/styles/chicago-fullnote-bibliography";
                "extensions.zotero.integration.useClassicAddCitationDialog" = true;
                "extensions.zotero.openURL.resolver" = "https://login.proxy006.nclive.org/login?url=https://resolver.ebscohost.com/openurl?";
                "extensions.zotero.sortAttachmentsChronologically" = true;
                "extensions.zotero.sortNotesChronologically" = true;
                "intl.locale.requested" = "en-US";
              }
            '';
            description = ''
              Attribute set of Zotero preferences.

              Zotero only supports int, bool, and string types for
              preferences, but home-manager will automatically
              convert all other JSON-compatible values into strings.
            '';
          };

          extraConfig = mkOption {
            type = types.lines;
            default = "";
            description = ''
              Extra preferences to add to <filename>user.js</filename>.
            '';
          };

          userChrome = mkOption {
            type = types.lines;
            default = "";
            description = "Custom Zotero user chrome CSS.";
          };
        };
      }
      ));

      default = { };
      description = "Attribute set of Zotero profiles.";
    };
  };

  config = mkIf cfg.enable {
    assertions = [
      (
        let
          defaults =
            catAttrs "name" (filter (a: a.isDefault) (attrValues cfg.profiles));
        in
        {
          assertion = cfg.profiles == { } || length defaults == 1;
          message = "Must have exactly one default Zotero profile but found "
            + toString (length defaults) + optionalString (length defaults > 1)
            (", namely " + concatStringsSep ", " defaults);
        }
      )

      (
        let
          duplicates = filterAttrs (_: v: length v != 1) (zipAttrs
            (mapAttrsToList (n: v: { "${toString v.id}" = n; }) cfg.profiles));

          mkMsg = n: v: "  - ID ${n} is used by ${concatStringsSep ", " v}";
        in
        {
          assertion = duplicates == { };
          message = ''
            Must not have Zotero profiles with duplicate IDs but
          '' + concatStringsSep "\n" (mapAttrsToList mkMsg duplicates);
        }
      )
    ];

    home.packages = [ cfg.package ];

    home.file = mkMerge ([{
      "${profilesPath}/profiles.ini" =
        mkIf (cfg.profiles != { }) { text = profilesIni; };
    }] ++ flip mapAttrsToList cfg.profiles (_: profile: {
      "${profilesPath}/${profile.path}/.keep".text = "";

      "${profilesPath}/${profile.path}/chrome/userChrome.css" =
        mkIf (profile.userChrome != "") { text = profile.userChrome; };

      "${profilesPath}/${profile.path}/user.js" = mkIf (profile.settings != { } || profile.extraConfig != "") {
        text =
          mkUserJs
            (profile.settings // { "extensions.zotero.firstRun2" = false; })
            profile.extraConfig;
      };
    }));
  };
}

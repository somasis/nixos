{ config
, lib
, pkgs
, ...
}:

let
  opt = options.programs.newsraft;
  cfg = config.programs.newsraft;
  pkg = config.programs.newsraft.package;

  inherit (lib) types;

  inherit (lib.options)
    mkOption
    mkEnableOption
    mkPackageOption
    ;
in
{
  options.programs.newsraft = {
    enable = mkEnableOption "newsraft";

    package = mkPackageOption pkgs "newsraft" { };

    sections = mkOption {
      default = {
        Global = {
          itemLimit = null;
          updateFrequency = null;
        };
      };

      description = "Sections that feeds may be categorized under.";

      type = types.listOf (types.submodule (
        { name, ... }: {
          options = {
            name = mkOption {
              type = types.nonEmptyStr;
              default = name;
              readOnly = true;
              description = "Section name.";
              defaultDescription = "attribute name";
            };

        itemLimit = mkOption {
          description = "How many of this section's items may be kept in the database. Per-feed item limits override this setting.";
          type = types.ints.unsigned;
          default = 0;
          example = 1000;
        };

        updateFrequency = mkOption {
          description = "How often to automatically update this section's feeds (in minutes). Per-feed item limits override this setting.";
          type = types.ints.unsigned;
          default = 0;
          example = 60;
        };
          };
        }
      ));

        name = mkOption {
          description = ''
            The URL to use for fetching the feed.

            Valid feed formats are documented in newsraft(1) "FORMATS SUPPORT".
          '';

          # See <src/feeds-parse.c> for the list of supported protocols.
          type = with types; either null (strMatching "^(http|https|file|ftp|gopher|gophers)://\S+$");
          default = null;
        };

        generator = mkOption {
          description = "Command that generates the feed content.";
          type = types.nonEmptyStr;
          default = null;
          example = "cat ~/local-feed.xml";
        };

        title = mkOption {
          description = "Title to be used for the feed.";
          type = types.nullOr types.str;
          default = null;
        };

        section = mkOption {
          description = "Section that the feed should be put under.";
          type = types.nullOr types.nonEmptyStr;
          default = null;
        };

        itemLimit = mkOption {
          description = "How many of this feed's items may be kept in the database.";
          type = types.ints.unsigned;
          default = 0;
          example = 1000;
        };

        updateFrequency = mkOption {
          description = "How often to automatically update this feed (in minutes).";
          type = types.ints.unsigned;
          default = 0;
          example = 60;
        };
      });
    };
  };

    feeds = mkOption {
      default = [ ];
      description = "A list of feeds.";
      type = types.listOf (types.submodule {
        url = mkOption {
          description = ''
            The URL to use for fetching the feed.

            Valid feed formats are documented in newsraft(1) "FORMATS SUPPORT".
          '';

          # See <src/feeds-parse.c> for the list of supported protocols.
          type = with types; either null (strMatching "^(http|https|file|ftp|gopher|gophers)://\S+$");
          default = null;
        };

        generator = mkOption {
          description = "Command that generates the feed content.";
          type = types.nonEmptyStr;
          default = null;
          example = "cat ~/local-feed.xml";
        };

        title = mkOption {
          description = "Title to be used for the feed.";
          type = types.nullOr types.str;
          default = null;
        };

        section = mkOption {
          description = "Section that the feed should be put under.";
          type = types.nullOr types.nonEmptyStr;
          default = null;
        };
      });
    };
  };

  config = {
    assertions = [
      {
        assertion = map (feed: (feed.url == null) && (feed.generator == null)) cfg.feeds;
        message = "All feeds must have a URL or a generator specified.";
      }
      {
        assertion = map (feed: (feed.url != null) && (feed.generator != null)) cfg.feeds;
        message = "No feed may have a URL and a generator specified.";
      }
    ];

    home.packages = [ pkg ];

    xdg.configFile."newsraft/feeds".text =
      let
        quote = x: ''"${lib.escape [ "\"" ] x}"'';

        feedsInSection = section: lib.filter (feed: feed.section == section) cfg.feeds;

        mkSectionLine = section:
          lib.concatStringsSep " " (
            [ "@" (quote section.name) ]
            ++ (lib.optional (section.updateFrequency != null) "[${section.updateFrequency}]")
            ++ (lib.optional (section.itemLimit != null) "{${section.itemLimit}}")
          );

        mkFeedLine = feed:
          lib.concatStringsSep " " (
            [ (feed.url or "$(${feed.generator})") ]
            ++ (lib.optional (feed.title != null) (quote feed.title))
            ++ (lib.optional (feed.updateFrequency != null) "[${feed.updateFrequency}]")
            ++ (lib.optional (feed.itemLimit != null) "{${feed.itemLimit}}")
          );

        mkSection = section:
          lib.concatLines (
            [ (mkSectionLine section) ]
            ++ (map (feedInSection: mkFeedLine feedInSection) (feedsInSection section))
          );
      in
      lib.concatLines (
        [ ]
        ++ (map (mkFeedLine) (feedsInSection null)) # Print global/unsectioned feeds first.
        ++ (map (mkSectionLine) cfg.sections)
      );
  };
}

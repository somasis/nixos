{ config
, lib
, pkgs
, ...
}:
let
  inherit (config.lib.somasis) feeds;

  philpapers =
    { keyword
    , title ? "PhilPapers: ${keyword}"
    , proOnly ? false
    , publishedOnly ? true
    , sort ? "pubYear"
    , tags ? [ "philosophy" keyword ]
    , extraTags ? [ ]
    }:
    let
      inherit (lib) escapeURL;

      bool = b: if b then "on" else "off";
      tags' = tags ++ lib.optionals (extraTags != null) tags;
    in
    {
      url = "https://philpapers.org/asearch.pl?format=rss&filterMode=keywords&searchStr=${escapeURL keyword}&proOnly=${escapeURL (bool proOnly)}&publishedOnly=${escapeURL (bool publishedOnly)}&sort=${escapeURL sort}";
      inherit title;
      tags = tags';
    };
in
{
  imports = [
    ./citation.nix
    ./editing.nix
    ./reading.nix
    ./writing.nix
  ];

  persist.directories = [{ method = "symlink"; directory = "study"; }];

  xdg.userDirs.documents = "${config.home.homeDirectory}/study/current";

  programs.zotero.profiles.default.settings = {
    "extensions.zotero.dataDir" = "${config.xdg.dataHome}/zotero";

    # ZotFile > General Settings > "Location of Files"
    "extensions.zotfile.dest_dir" = "${config.home.homeDirectory}/study/doc";
  };

  lib.somasis.feeds.feeds = { inherit philpapers; };

  programs.newsboat.urls = [
    {
      url = "https://marxandphilosophy.org.uk/feed/?post_type=review";
      title = "Marx & Philosophy: review of books";
      tags = [ "philosophy" "marxism" "reviews" ];
    }
    {
      url = "https://curedquailjournal.wordpress.com/feed/";
      title = "Cured Quail: blog";
      tags = [ "philosophy" ];
    }
    {
      url = "https://dj.dancecult.net/index.php/dancecult/gateway/plugin/WebFeedGatewayPlugin/atom";
      title = "Dancecult: Journal of Electronic Dance Music Culture";
      tags = [ "journals" "music" ];
    }
    {
      url = "https://onlinelibrary.wiley.com/feed/14678675/most-recent";
      title = "Constellations";
      tags = [ "journals" "philosophy" ];
    }
    {
      url = "https://www.cambridge.org/core/rss/product/id/F3D70AB528A9726BC052F1AEB771A611";
      title = "Hypatia";
      tags = [ "philosophy" "journal" ];
    }
    {
      url = "https://www.parapraxismagazine.com/articles/?format=rss";
      title = "Parapraxis";
      tags = [ "philosophy" ];
    }
    {
      url = "https://www.radicalphilosophy.com/feed";
      title = "Radical Philosophy";
      tags = [ "philosophy" "journal" ];
    }
    {
      url = "https://thepointmag.com/feed/";
      title = "The Point";
      tags = [ "criticism" "philosophy" ];
    }

    (philpapers { keyword = "polyamory"; })
    # (philpapers { keyword = "gender"; })
    # TODO: Does Duke University Press have a feed for Transgender Studies Quarterly?
  ];
}

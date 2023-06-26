{ config
, lib
, pkgs
, ...
}:
let
  inherit (lib) getBin makeBinPath;
  inherit (config.lib.somasis) feeds writeJqScript;
  inherit (pkgs) writeScript writeShellScript;

  filterSubredditJson = writeJqScript "filter-subreddit" { } ''
    .data.children |= map(
      select(
        (.kind == "t3") and (.data.stickied == false)
      )
    )
  '';

  subredditJsonToAtomJson = writeJqScript "subreddit-json-to-atomjson" { } ''
    {
      feed: {
        "+@xmlns": "http://www.w3.org/2005/Atom",

        id: "/r/\($ARGS.named["subreddit"])",
        title: "Reddit: /r/\($ARGS.named["subreddit"])",

        entry: (
          .data.children
            | map(
              (.data.post_hint // "text") as $post_type
                | {
                  id: .data.permalink,
                  updated: (try (.data.created_utc | todate)),

                  author: {
                    uri: "https://reddit.com/u/\(.data.author)",
                    name: ("/u/\(.data.author)" + (if .data.author_flair_text != null then " (\(.data.author_flair_text))" else "" end))
                  },

                  title: {
                    "+@type": "text",
                    "+content": (
                      if .data.link_flair_text != null then
                        "\(.data.link_flair_text): \(.data.title)"
                      else
                        .data.title
                      end
                    )
                  },

                  link: (
                    if $post_type == "text" then
                      [
                        { "+@rel": "alternate", "+@title": "Comments", "+@href": "https://www.reddit.com\(.data.permalink)" }
                      ]
                    else
                      [
                        { "+@rel": "alternate", "+@title": "Link", "+@href": .data.url },
                        { "+@rel": "related", "+@title": "Comments", "+@href": "https://www.reddit.com\(.data.permalink)" }
                      ]
                    end
                  ),

                  content: (
                    if .data.is_self == true then
                      {
                        "+@type": "html",
                        "+content": .data.selftext_html
                      }
                    else
                      # akin to hnrss.com's content format
                      "Article URL: \(.data.url)\n\n"
                        + "Comments URL: https://www.reddit.com\(.data.permalink)\n\n"
                        + "Points: \(.data.score)\n\n"
                        + "# Comments: \(.data.num_comments)"
                    end
                  )
                }
          )
        )
      }
    }
  '';

  generateReddit = writeShellScript "generate-reddit" ''
    PATH=${makeBinPath [ config.programs.jq.package pkgs.curl pkgs.yq-go pkgs.coreutils pkgs.moreutils ] }:$PATH

    [[ -t 0 ]] || cat > /dev/null

    [[ "$#" -eq 0 ]] && set -- .
    subreddit="''${1:-all}"; shift
    filter="''${1:-}"; shift
    jq_args=(
        --arg subreddit "$subreddit"
        "$@"
    )

    umask 0077

    runtime=$(mktemp -d)
    trap 'cd /; rm -rf "$runtime"' EXIT

    cd "$runtime"

    curl -Lf -o subreddit.json "https://www.reddit.com/r/$subreddit/.json"
    [[ -s subreddit.json ]] || exit 1

    ${filterSubredditJson} "''${jq_args[@]}" subreddit.json > filtered.json

    [[ -n "$filter" ]] \
        && $filter "''${jq_args[@]}" filtered.json \
        | ifne sponge filtered.json

    ${subredditJsonToAtomJson} "''${jq_args[@]}" filtered.json > feed.json

    yq -p json -o xml --xml-strict-mode < feed.json
  '';

  reddit =
    { subreddit
    , title ? "Reddit: /r/${subreddit}"
    , tags ? [ "aggregator" "reddit" ]
    , extraTags ? [ ]
    , filter ? ""
    , pointsInTitle ? true
    }:
      assert (lib.isString subreddit);
      assert (lib.isString title);
      assert (lib.isList tags);
      assert (lib.isList extraTags);
      assert (lib.isString filter);
      assert (lib.isBool pointsInTitle);
      let
        filter' =
          if filter != "" then
            writeJqScript "jq-filter" { } ''
              .data.children |= map_values(${filter})
            ''
          else
            ""
        ;
        tags' = tags ++ lib.optionals (extraTags != null) tags;
      in
      {
        # urls.filter is used so as to benefit from caching
        url = feeds.urls.filter "https://www.reddit.com/r/${subreddit}.rss"
          (pkgs.writeShellScript "generate-reddit-with-filter" ''
            exec ${generateReddit} ${lib.escapeShellArg subreddit} ${lib.escapeShellArg filter'} --arg points_in_title ${lib.boolToString pointsInTitle}
          '');
        inherit title;
        tags = tags';
      }
  ;

  lemmy =
    { community
    , sort ? "Active"
    , title ? "Lemmy: ${community}"
    , tags ? [ "aggregator" "lemmy" ]
    , extraTags ? [ ]
    , instance ? "https://lemmy.ml"
    }:
      assert (builtins.isString community);
      assert (builtins.isString sort);
      assert (builtins.isString title);
      assert (builtins.isList tags);
      assert (builtins.isList extraTags);
      assert (builtins.isString instance);
      let
        tags' = tags ++ lib.optionals (extraTags != null) tags;
      in
      {
        url = "${instance}/feeds/c/${community}.xml?sort=${sort}";
        inherit title;
        tags = tags';
      };
in
{
  lib.somasis.feeds.feeds = {
    inherit
      reddit
      lemmy
      ;
  };

  programs.newsboat.urls = [
    { tags = [ "aggregator" ]; url = "https://hnrss.org/frontpage"; title = "Hacker News"; }
    { tags = [ "aggregator" ]; url = "https://hnrss.org/show"; title = "Hacker News: show"; }

    {
      url = feeds.urls.secret "https://lobste.rs/rss?token=%s" "www/lobste.rs/somasis.rss";
      title = "Lobsters";
      tags = [ "aggregator" ];
    }

    {
      url = "https://tilde.news/rss";
      tags = [ "aggregator" ];
    }

    {
      url = "https://discourse.nixos.org/c/links/12.rss";
      title = "NixOS Discourse: links";
      tags = [ "aggregator" "NixOS" ];
    }

    # (reddit { subreddit = "Spanish"; extraTags = [ "es" ]; })

    # (reddit { subreddit = "NorthCarolina"; extraTags = [ "local" ]; })
    # (reddit { subreddit = "WNC"; extraTags = [ "local" ]; })
    # (reddit { subreddit = "appstate"; extraTags = [ "local" ]; })
    # (reddit { subreddit = "boone"; extraTags = [ "local" ]; })

    # (reddit { subreddit = "openstreetmap"; extraTags = [ "osm" ]; })

    # (reddit { subreddit = "BSD"; extraTags = [ "computer" ]; })
    # (reddit { subreddit = "MicroG"; extraTags = [ "computer" ]; })
    # (reddit { subreddit = "NixOS"; extraTags = [ "computer" ]; })
    # (reddit { subreddit = "bspwm"; extraTags = [ "computer" ]; })
    # (reddit { subreddit = "commandline"; extraTags = [ "computer" ]; })
    # (reddit { subreddit = "coolgithubprojects"; extraTags = [ "computer" ]; })
    # (reddit { subreddit = "pkgoftheday"; extraTags = [ "computer" ]; })
    # (reddit { subreddit = "plaintextaccounting"; extraTags = [ "computer" ]; })
    # (reddit { subreddit = "qutebrowser"; extraTags = [ "computer" ]; })
    # (reddit { subreddit = "regex"; extraTags = [ "computer" ]; })
    # (reddit { subreddit = "RetroArch"; extraTags = [ "computer" ]; })
    # (reddit { subreddit = "framework"; extraTags = [ "computer" ]; })
    # (reddit { subreddit = "tmux"; extraTags = [ "computer" ]; })
    # (reddit { subreddit = "userscripts"; extraTags = [ "computer" ]; })
    # (reddit { subreddit = "zfs"; extraTags = [ "computer" ]; })

    # (reddit { subreddit = "FL_Studio"; extraTags = [ "computer" "music" ]; })
    # (reddit { subreddit = "macdemarco"; extraTags = [ "music" ]; })
    # (reddit { subreddit = "SweetTrip"; extraTags = [ "music" ]; })
    # (reddit { subreddit = "vintageobscura"; extraTags = [ "music" ]; })

    # (reddit { subreddit = "splatoon"; extraTags = [ "game" ]; })

    # (reddit { subreddit = "tokipona"; extraTags = [ "toki pona" ]; })
    # (reddit { subreddit = "tokiponataso"; extraTags = [ "toki pona" ]; })
    # (reddit { subreddit = "mi_lon"; extraTags = [ "toki pona" ]; })
    # (reddit { subreddit = "sitelen_musi"; extraTags = [ "toki pona" ]; })

    # (reddit { subreddit = "CriticalTheory"; extraTags = [ "philosophy" ]; })
    # (reddit { subreddit = "Scholar"; extraTags = [ "philosophy" ]; })
    # (reddit { subreddit = "askphilosophy"; extraTags = [ "philosophy" ]; })
    # (reddit { subreddit = "badphilosophy"; extraTags = [ "philosophy" ]; })
    # (reddit { subreddit = "philosophy"; extraTags = [ "philosophy" ]; })

    (reddit {
      subreddit = "oilshell";
      filter = ''
        select(.data.author == "oilshell") | select(.data.domain == "oilshell.org")
      '';
      title = "Oil Shell";
      tags = [ "blog" "computer" ];
      pointsInTitle = false;
    })

    (lemmy { community = "technology"; })
    (lemmy { community = "worldnews"; })
    (lemmy { community = "usa"; title = "Lemmy: USA"; })
  ];
}

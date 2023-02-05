{ config
, nixosConfig
, lib
, pkgs
, ...
}:
let
  tor = nixosConfig.services.tor;
  userAgent = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/97.0.4692.99 Safari/537.36";
in
{
  programs.newsboat = {
    enable = true;

    browser = builtins.toString (pkgs.writeShellScript "newsboat-browser" ''
      ${pkgs.coreutils}/bin/nohup ${pkgs.xdg-utils}/bin/xdg-open "$1" >/dev/null 2>&1 &
    '');

    extraConfig =
      let
        newsboatHTMLRenderer = pkgs.writeShellScript "newsboat-html-renderer" ''
          ${pkgs.rdrview}/bin/rdrview \
              -T body \
              -H "$@" \
              | ${pkgs.html-tidy}/bin/tidy \
                  -q \
                  -asxml \
                  -w 0 2>/dev/null \
              | ${pkgs.w3m-nox}/bin/w3m \
                  -dump \
                  -T text/html
        '';
      in
      ''
        download-full-page yes

        mark-as-read-on-hover yes

        articlelist-format "%4i %f %D %?T?|%-17T| ?%t"
        datetime-format %Y-%m-%d
        feedlist-format "%4i %n %11u %t%?T? #%T? "

        text-width 100

        cache-file "${config.xdg.cacheHome}/newsboat/cache.db"

        html-renderer "${newsboatHTMLRenderer}"
        user-agent "${userAgent}"
      ''
      + lib.optionalString (tor.enable && tor.client.enable) ''
        # socks5h: "CURLPROXY_SOCKS5_HOSTNAME [...] Proxy resolves URL hostname."
        use-proxy yes
        proxy ${tor.client.socksListenAddress.addr}:${toString tor.client.socksListenAddress.port}
        proxy-type socks5h
      ''
    ;

    # Create a list of queries from all URLs' tags.
    queries = { "!!! unread" = ''unread = "yes"''; }
      // (lib.foldr (a: b: a // b) { } (
      builtins.map (x: { "... ${x}" = ''tags # "${x}"''; }) (lib.unique (lib.concatLists (lib.catAttrs "tags" config.programs.newsboat.urls)))));

    urls =
      let
        discardContent = f: ''"filter:''
          + builtins.toString (pkgs.writeShellScript "discard-content" ''
          ${pkgs.xmlstarlet}/bin/xml ed \
            -d '//channel/item/description' \
            -d '//channel/item/content:encoded' \
            -d '//feed/entry/content'
        '')
          + '':${f}"'';

        feedRedacted = f: ''"exec:''
          + builtins.toString (pkgs.writeShellScript "generate-redacted" ''
          PATH=${lib.makeBinPath [ pkgs.curl config.programs.password-store.package ]}:"$PATH"

          unset http_proxy HTTPS_PROXY ALL_PROXY

          entry=www/redacted.ch

          url="$1"
          url+="&user=$(pass meta "$entry" uid)"
          url+="&auth=$(pass meta "$entry" auth)"
          url+="&passkey=$(pass meta "$entry" passkey)"
          url+="&authkey=$(pass meta "$entry" authkey)"

          curl \
              --disable \
              --silent \
              --show-error \
              --fail \
              --globoff \
              --disallow-username-in-url \
              --connect-timeout 60 \
              --max-time 60 \
              --retry 10 \
              --limit-rate 512K \
              --parallel \
              --parallel-max 4 \
              --noproxy '*' \
              -K - \
              <<< "url = $url"
        '')
          + '' https://redacted.ch/feeds.php?feed=${f}"'';

        generateReddit = pkgs.writeShellScript "generate-reddit" ''
          umask 0077

          subreddit="$1"
          shift
          jq="''${2:-}"

          json=$(${pkgs.coreutils}/bin/mktemp)
          trap '${pkgs.coreutils}/bin/rm -f "''${json}"' EXIT

          autocurl -Lf -o "''${json}" "https://www.reddit.com/r/''${subreddit}/.json"

          [[ -s "''${json}" ]] || exit 1

          <"''${json}" ${config.programs.jq.package}/bin/jq -r --arg subreddit "''${subreddit}" '
              "<?xml version=\"1.0\" encoding=\"utf-8\"?><feed xmlns=\"http://www.w3.org/2005/Atom\"><title>/r/\($subreddit)</title><id>https://www.reddit.com/r/\($subreddit)</id><link rel=\"alternate\" href=\"https://www.reddit.com/r/\($subreddit)\" /><updated>\(.data.children[0].data.created_utc | todate)</updated>",
              (
                  .data.children
                      | map(
                          select(.kind == "t3" and (.data | .stickied == false'"''${jq:+ and ''${jq}}"'))
                              | .data
                              | (((.link_flair_text // empty | "\(.): ") // null) + .title) as $title
                              | (.created_utc | todate) as $updated
                              | (
                                  if .is_self == true then
                                      "<content type=\"text/html\">\(.selftext_html)</content>"
                                  else
                                      ""
                                  end
                              ) as $content
                              | "<entry><title>\($title)</title><id>https://www.reddit.com\(.permalink)</id><link rel=\"related\" title=\"Comments\" type=\"text/html\" href=\"https://www.reddit.com\(.permalink)\" /><link rel=\"alternate\" title=\"Article\" href=\"\(.url)\" /><updated>\($updated)</updated><author><name>\(.author)</name></author>\($content)</entry>"
                      )[]
              ),
              "</feed>"
          '
        '';

        feedReddit = { subreddit, tags ? [ ] }: {
          url = "https://www.reddit.com/r/${subreddit}/.rss";
          title = "Reddit: /r/${subreddit}";
          tags = [ "reddit" ] ++ tags;
        };
      in
      [
        # Academia
        {
          url = "https://www.cambridge.org/core/rss/product/id/F3D70AB528A9726BC052F1AEB771A611";
          title = "Hypatia";
          tags = [ "academia" "philosophy" ];
        }
        {
          url = "https://feministkilljoys.com/feed";
          title = "feministkilljoys";
          tags = [ "academia" "philosophy" ];
        }
        # TODO: Does Duke University Press have a feed for Transgender Studies Quarterly?

        # Blogs
        {
          url = "https://leahneukirchen.org/blog/index.atom";
          tags = [ "blog" "friends" ];
        }
        {
          url = "https://leahneukirchen.org/trivium/index.atom";
          tags = [ "blog" "friends" ];
        }
        {
          url = "https://text.causal.agency/feed.atom";
          tags = [ "blog" "computer" "friends" ];
        }
        {
          url = "https://www.7596ff.com/rss.xml";
          tags = [ "blog" "friends" ];
        }
        {
          url = "https://pikhq.com/index.xml";
          tags = [ "blog" "friends" ];
        }
        {
          url = "https://www.uninformativ.de/blog/feeds/en.atom";
          tags = [ "blog" "development" "computer" ];
        }
        {
          url = "https://dataswamp.org/~solene/rss.xml";
          tags = [ "blog" "computer" "OpenBSD" "NixOS" ];
        }
        {
          url = "https://determinate.systems/posts?format=rss";
          title = "Determinate Systems";
          tags = [ "computer" "NixOS" ];
        }
        {
          url = "https://flak.tedunangst.com/rss";
          title = "Ted Unangst: flak";
          tags = [ "blog" "OpenBSD" ];
        }
        {
          url = ''"exec:${generateReddit} \"oilshell\" \".is_self == false\""'';
          title = "Oil Shell";
          tags = [ "blog" "computer" ];
        }

        {
          url = "https://mforney.org/blog/atom.xml";
          tags = [ "blog" "computer" ];
        }
        {
          url = "https://ariadne.space/feed/";
          tags = [ "blog" "computer" ];
        }
        {
          url = "https://christine.website/blog.atom";
          tags = [ "blog" "computer" "friends" ];
        }
        {
          url = "https://whynothugo.nl/posts.xml";
          tags = [ "blog" "computer" ];
        }
        {
          url = "https://jcs.org/rss";
          tags = [ "blog" "computer" "OpenBSD" ];
        }
        {
          url = "https://hisham.hm/?x=feed:rss2&category=1";
          title = "hisham.hm";
          tags = [ "blog" "computer" ];
        }

        # Aggregators
        {
          url = "https://tilde.news/rss";
          tags = [ "aggregators" ];
        }

        {
          url = "https://discourse.nixos.org/c/links/12.rss";
          title = "NixOS Discourse: links";
          tags = [ "aggregators" "NixOS" ];
        }

        # Comics
        {
          url = "https://xkcd.com/atom.xml";
          tags = [ "comics" ];
        }
        {
          url = "https://rakhim.org/honestly-undefined/index.xml";
          title = "Honestly Undefined";
          tags = [ "comics" ];
        }

        # Computers
        {
          url = "https://latacora.micro.blog/feed.xml";
          tags = [ "blog" "computer" ];
        }
        {
          url = "https://sanctum.geek.nz/arabesque/feed/";
          tags = [ "blog" "computer" ];
        }
        {
          url = "https://ewontfix.com/feed.rss";
          tags = [ "blog" "computer" ];
        }
        {
          url = "https://beepb00p.xyz/atom.xml";
          tags = [ "blog" "computer" ];
        }
        {
          url = "https://onethingwell.org/rss";
          tags = [ "computer" "tumblr" ];
        }
        {
          url = "https://nixers.net/newsletter/feed.xml";
          tags = [ "computer" ];
        }

        # Forums
        {
          url = "https://discourse.nixos.org/c/announcements/8.rss";
          title = "NixOS Discourse: announcements";
          tags = [ "NixOS" ];
        }

        # Music
        {
          url = "https://constantlyhating.substack.com/feed";
          tags = [ "music" ];
        }
        {
          url = feedRedacted "feed_news";
          title = "Redacted: news";
          tags = [ "music" "redacted" ];
        }
        {
          url = feedRedacted "feed_blog";
          title = "Redacted: blog";
          tags = [ "music" "redacted" ];
        }

        # News
        {
          url = "https://lwn.net/headlines/newrss";
          tags = [ "news" "computer" ];
        }
        {
          url = "https://www.democracynow.org/democracynow.rss";
          tags = [ "news" ];
        }
        {
          url = "https://www.currentaffairs.org/feed";
          tags = [ "news" ];
        }
        {
          url = "https://thebaffler.com/feed";
          tags = [ "news" ];
        }
        {
          url = "https://theappalachianonline.com/feed/";
          title = "The Appalachian";
          tags = [ "news" "Appalachian State University" "Boone, NC" ];
        }
        {
          url = "https://www.townofboone.net/RSSFeed.aspx?ModID=63&CID=All-0";
          title = "Town of Boone: alerts";
          tags = [ "Boone, NC" "notification" ];
        }
        {
          url = "https://www.exploreboone.com/event/rss/";
          title = "Explore Boone: events";
          tags = [ "Boone, NC" ];
        }
        {
          url = "https://www.wataugademocrat.com/search/?f=rss&t=article&c=news/local&l=50&s=start_time&sd=desc";
          title = "Watauga Democrat: local news";
          tags = [ "news" "Boone, NC" ];
        }
        {
          url = "https://www.wataugademocrat.com/classifieds/?f=rss&s=start_time&sd=asc";
          title = "Watauga Democrat: classifieds";
          tags = [ "Boone, NC" ];
        }
        {
          url = "https://www.wataugademocrat.com/search/?f=rss&t=article&c=news/asu_news&l=50&s=start_time&sd=desc";
          title = "Watauga Democrat: Appalachian State University news";
          tags = [ "Appalachian State University" "Boone, NC" "news" ];
        }
        {
          url = "https://wataugaonline.com/feed/";
          title = "Watauga Online";
          tags = [ "Boone, NC" "news" ];
        }
        {
          url = "https://feeds.feedburner.com/HCPress";
          title = "High Country Press";
          tags = [ "Boone, NC" "news" ];
        }

        # Notifications
        {
          url =
            let
              generate = pkgs.writeShellScript "generate" ''
                ${config.programs.password-store.package}/bin/pass \
                    www/github.com/somasis.private.atom \
                    | ${pkgs.coreutils}/bin/tr -d '\n' \
                    | autocurl -Lf -G --data-urlencode "token@-" "https://github.com/somasis.private.atom"
              '';
            in
            "exec:${generate}";
          title = "GitHub: timeline";
          tags = [ "notification" ];
        }

        # OpenStreetMap
        {
          url = discardContent "https://www.weeklyosm.eu/feed";
          title = "weeklyOSM";
          tags = [ "news" "OpenStreetMap" ];
        }
        {
          url = "https://www.openstreetmap.org/api/0.6/notes/feed?bbox=-81.918076,36.111477,-81.455917,36.391293";
          title = "OpenStreetMap: notes in Watauga County";
          tags = [ "notification" "OpenStreetMap" ];
        }
        {
          url = "https://www.openstreetmap.org/api/0.6/notes/feed?bbox=-80.7872772,35.1850329,-80.2963257,35.5093128";
          title = "OpenStreetMap: notes in Cabarrus County";
          tags = [ "notification" "OpenStreetMap" ];
        }
        {
          url = "https://resultmaps.neis-one.org/osm-suspicious-feed-bbox?hours=96&mappingdays=-1&tsearch=review_requested%3Dyes&anyobj=t&bbox=-81.918076,36.111477,-81.455917,36.391293";
          title = "OpenStreetMap: changes to be reviewed in Watauga County";
          tags = [ "notification" "OpenStreetMap" ];
        }
        {
          url = "https://resultmaps.neis-one.org/osm-suspicious-feed-bbox?hours=96&mappingdays=-1&tsearch=review_requested%3Dyes&anyobj=t&bbox=-80.7872772,35.1850329,-80.2963257,35.5093128";
          title = "OpenStreetMap: changes to be reviewed in Cabarrus County";
          tags = [ "notification" "OpenStreetMap" ];
        }
        {
          url = "https://us3.campaign-archive.com/feed?u=162692bfdedb78ec46fd108a3&id=801ce00e6d";
          title = "OpenStreetMap US";
          tags = [ "newsletter" "OpenStreetMap" ];
        }
        {
          url = "https://osmand.net/rss.xml";
          tags = [ "development" "OpenStreetMap" ];
        }

        # Tumblr
        {
          url = "https://phidica.tumblr.com/rss";
          title = "Phidica";
          tags = [ "blog" "friends" "tumblr" ];
        }
        {
          url = "https://control--panel.com/rss";
          tags = [ "blog" "computer" "tumblr" ];
        }

        # System
        { url = "https://nixos.org/blog/announcements-rss.xml"; tags = [ "computer" "NixOS" ]; }
        { url = "file://${config.xdg.cacheHome}/newsboat/home-manager-news.atom"; tags = [ "computer" "NixOS" ]; title = "Home Manager"; }

        # YouTube
        {
          url = "https://www.youtube.com/feeds/videos.xml?channel_id=UCXnNibvR_YIdyPs8PZIBoEw";
          title = "YouTube: Cathode Ray Dude";
          tags = [ "YouTube" "tech" ];
        }
        {
          url = "https://www.youtube.com/feeds/videos.xml?channel_id=UCqdUXv9yQiIhspWPYgp8_XA";
          title = "YouTube: Road Guy Rob";
          tags = [ "YouTube" "urbanism" ];
        }
        {
          url = "https://www.youtube.com/feeds/videos.xml?channel_id=UC18ju52OET36bdewLRHzPdQ";
          title = "YouTube: brutalmoose";
          tags = [ "YouTube" ];
        }
        {
          url = "https://www.youtube.com/feeds/videos.xml?channel_id=UCy0tKL1T7wFoYcxCe0xjN6Q";
          title = "YouTube: Technology Connections";
          tags = [ "YouTube" "technology" ];
        }
        {
          url = "https://www.youtube.com/feeds/videos.xml?channel_id=UCW5OrUZ4SeUYkUg1XqcjFYA";
          title = "YouTube: GeoWizard";
          tags = [ "YouTube" "geography" ];
        }

        # toki pona
        {
          url = "https://feeds.redcircle.com/901407e0-53e9-4aa2-aa3d-509393d10783";
          title = "kalama sin";
          tags = [ "toki pona" "podcast" ];
        }
        {
          url = "https://jonathangabel.com/feed.xml";
          title = "jan Josan";
          tags = [ "toki pona" "blog" ];
        }
        {
          url = "https://janketami.wordpress.com/feed/";
          title = "jan Ke Tami";
          tags = [ "toki pona" "blog" ];
        }
        {
          url = "https://kijetesantakalu-o.tumblr.com/rss";
          title = "kijetesantakalu o!";
          tags = [ "toki pona" "blog" "comics" ];
        }

        (feedReddit { subreddit = "tokipona"; tags = [ "toki pona" ]; })
        (feedReddit { subreddit = "tokiponataso"; tags = [ "toki pona" ]; })
        (feedReddit { subreddit = "mi_lon"; tags = [ "toki pona" ]; })
        (feedReddit { subreddit = "sitelen_musi"; tags = [ "toki pona" ]; })
      ];
  };

  home.activation =
    let
      jqFilterNews = (pkgs.writeScript "jq-filter-news" ''
        #!${config.programs.jq.package}/bin/jq -f
        map(select(.condition == true))
            | sort_by(.time)
            | map(
                . + {
                # Generate titles for feed items
                #   1. Strip any ending punctuation (for when it's a short message)
                #   2. Crudely un-hardwrap the first line of the message
                #   3. Keep only the first line of the message
                #   4. Remove any remaining ending punctuation
                  title: (
                      .message
                          | sub("\\.?\n$|:\n.*"; ""; "p")
                          | sub(
                              "(?<pre>[^\\s]+)\n(?<suf>[^\n]+).*";
                              "\(.pre) \(.suf)";
                              "pg"
                          )
                          | rtrimstr(".")
                  )
                }
            )
            | map_values(.id = (.time + .message | @base64))
            # Now, shape our input in terms that yq can output as xml, and that
            | {
                feed: {
                  "@xmlns": "http://www.w3.org/2005/Atom",
                  title: "home-manager",
                  updated: (map(.time) | sort | last),
                  entry: map(
                    {
                      id,
                      updated: .time,
                      title: { "@text": "text", "#text": .title },
                      content: { "@type": "text/plain", "#text": .message }
                    }
                  )
                }
            }
      '');
    in
    {
      generateHomeManagerNews = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        export PATH=${lib.makeBinPath [ config.programs.jq.package pkgs.yq ]}:"$PATH"
        umask 0077

        # don't lint the json declaration
        # shellcheck disable=all
        {
            ${lib.toShellVar "json" (builtins.toJSON config.news.entries)}
            ${lib.toShellVar "jqFilterNews" jqFilterNews}
        }

        [ -n "''${VERBOSE:-}" ] && set -x
        [ -n "''${DRY_RUN:-}" ] && set -nv

        jq -f "$jqFilterNews" <<<"$json" \
            | yq --xml-output \
            | xq --xml-output --xml-dtd \
            > "${config.xdg.cacheHome}/newsboat/home-manager-news.atom"
        touch "${config.xdg.cacheHome}/newsboat/home-manager-news.atom"
      '';
    };


  home.persistence."/cache${config.home.homeDirectory}".directories = [ "var/cache/newsboat" ];

  systemd.user = {
    targets.feeds = {
      Unit = {
        Description = "All feed-related services";
        PartOf = [ "default.target" ];
      };
      Install.WantedBy = [ "default.target" ];
    };

    services.feeds = {
      Unit = {
        Description = "Update feeds";
        PartOf = [ "feeds.target" ];
      };
      Install.WantedBy = [ "feeds.target" ];

      Service = {
        Type = "oneshot";
        ExecStart = [ "-${pkgs.newsboat}/bin/newsboat -x reload" ];
        ExecStartPost = [ "-${pkgs.newsboat}/bin/newsboat --cleanup" ];

        Nice = 19;
        CPUSchedulingPolicy = "idle";
        IOSchedulingClass = "idle";
        IOSchedulingPriority = 7;
      };
    };

    timers.feeds = {
      Unit = {
        Description = "Update feeds every day";
        PartOf = [ "feeds.target" ];
      };
      Install.WantedBy = [ "feeds.target" ];

      Timer = {
        OnCalendar = "daily";
        Persistent = true;
        AccuracySec = "15m";
        RandomizedDelaySec = "15m";
      };
    };
  };

  programs.qutebrowser.keyBindings.normal."<z><p><f>" =
    let
      quteFeeds = pkgs.writeShellScript "qute-feeds" ''
        set -eu
        set -o pipefail

        : "''${QUTE_FIFO:?}"
        : "''${QUTE_HTML:?}"

        feeds=$(${pkgs.sfeed}/bin/sfeed_web "$1" <"$QUTE_HTML")

        [ -n "$feeds" ] ||
              printf 'message-warning "%s"\n' \
                  "feeds: No feeds were found." \
                  > "''${QUTE_FIFO}"

        dmenu -p "qutebrowser [feeds]:" \
            | cut -f1 \
            | ${pkgs.xclip}/bin/xclip -i -selection clipboard

        [ -n "$feeds" ] ||
              printf 'message-info "%s"\n' \
                  "feeds: Copied feed to clipboard." \
                  > "''${QUTE_FIFO}"
      '';
    in
    "spawn -u ${quteFeeds} {url:domain}";
}

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
        curl = lib.escapeShellArgs (
          [ "${pkgs.curl}/bin/curl" "-A" "${userAgent}" ]
          ++ (lib.optionals (tor.enable && tor.client.enable) [ "-x" "socks5h://${tor.client.socksListenAddress.addr}:${toString tor.client.socksListenAddress.port}" ])
        )
        ;

        discardContent = pkgs.writeShellScript "discard-content" ''
          umask 0077

          feed="$1"
          shift

          ${curl} -Lf "''${feed}" \
              | ${pkgs.xmlstarlet}/bin/xml ed \
                  -d '//channel/item/description' \
                  -d '//channel/item/content:encoded' \
                  -d '//feed/entry/content'
        '';

        # generateRedacted = pkgs.writeShellScript "generate-redacted" ''
        #   entry=www/redacted.ch

        #   url="$1?"
        #   for k in uid auth passkey authkey; do
        #       url="$k=$(${config.programs.password-store.package}/bin/pass meta "$entry" "$k")&"
        #   done
        #   url=${url%&}

        #   ${pkgs.curl}/bin/curl \
        #         -K - \
        #         --noproxy "*" \
        #         -Lf \
        #         <<< "$url"
        # '';

        generateReddit = pkgs.writeShellScript "generate-reddit" ''
          umask 0077

          subreddit="$1"
          shift
          jq="''${2:-}"

          json=$(${pkgs.coreutils}/bin/mktemp)
          trap '${pkgs.coreutils}/bin/rm -f "''${json}"' EXIT

          ${curl} -Lf -o "''${json}" "https://www.reddit.com/r/''${subreddit}/.json"

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

        generateNews = pkgs.writeShellApplication {
          name = "generate-news";

          runtimeInputs = [
            config.programs.jq.package
            pkgs.coreutils
            pkgs.pandoc
          ];

          text = ''
            umask 0077

            # shellcheck disable=SC2016
            # don't lint the json declaration
            ${lib.toShellVar "json" (builtins.toJSON config.news.entries)}

            cat <<EOF
            <?xml version="1.0" encoding="utf-8"?>
            <feed xmlns="http://www.w3.org/2005/Atom">
            <title>home-manager</title>
            EOF

            # Convert to TSV (from <https://stackoverflow.com/a/51929863>)
            <<< "$json" \
                jq -r '
                    [ [ paths(scalars)[1:] | tojson ] | unique[] | fromjson ] as $p
                        | [
                            (
                                $p[]
                                | map(if type=="number" then "[\(.)]" else ".\(.)" end)
                                | join("")
                            )
                        ],
                        (.[] | [getpath($p[])]) | @tsv
                ' \
                | tail -n +2 \
                | while IFS=$(printf '\t') read -r condition id content date; do
                    # shellcheck disable=SC2001
                    content=$(sed 's/\\t/\t/g; s/\\n/\n/g' <<< "''${content}")
                    title=$(pandoc -f markdown-raw_html+smart -t plain --wrap=none <<< "''${content}" | sed 's/[\.:]$//' | head -n1 | tr -d '\n' | base64 -w0)
                    content=$(pandoc -f markdown-raw_html+smart -t html --wrap=none <<< "''${content}" | base64 -w0)

                    printf '%s\t%s\t%s\t%s\t%s\n' "$title" "$date" "$condition" "$id" "$content"
                done \
                | sort -t $'\t' -k2 \
                | jq -rRs '
                    split("\n")[:-1]
                        | map(
                            [ split("\t") ][]
                                | { title: (.[0] | @base64d), date: .[1], condition: .[2], id: .[3], content: (.[4] | @base64d) }
                        )
                ' \
                | jq -r '
                    sort_by(.date)
                        | map("<entry><title type=\"html\">\(.title)</title><id>\(.id)</id><updated>\(.date)</updated><content type=\"html\">\(.content | @html)</content></entry>")[]
                '

            cat <<EOF
            </feed>
            EOF
          '';
        };
      in
      [
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
          tags = [ "blog" "computer" ];
        }
        {
          url = "https://maxice8.github.io/rss.xml";
          tags = [ "blog" "computer" ];
        }
        {
          url = "https://waldon.blog/feed";
          tags = [ "blog" "computer" ];
        }
        {
          url = "https://dataswamp.org/~solene/rss.xml";
          tags = [ "blog" "computer" "OpenBSD" "NixOS" ];
        }
        {
          url = "https://determinate.systems/posts?format=rss";
          tags = [ "computer" "NixOS" ];
        }
        {
          url = "https://flak.tedunangst.com/rss";
          title = "Ted Unangst: flak";
          tags = [ "blog" "computer" "OpenBSD" ];
        }
        {
          url = "https://apenwarr.ca/log/rss.php";
          tags = [ "blog" "computer" ];
        }
        {
          title = "Oil Shell";
          url = ''"exec:${generateReddit} \"oilshell\" \".is_self == false\""'';
          tags = [ "blog" "computer" "programming" ];
        }
        {
          title = "Reddit: toki pona";
          url = ''"exec:${generateReddit} \"tokipona+tokiponataso+mi_lon+sitelen_musi\""'';
          tags = [ "reddit" "toki pona" ];
        }
        {
          title = "Reddit: sitelen musi pi toki pona";
          url = ''"exec:${generateReddit} \"mi_lon+sitelen_musi\""'';
          tags = [ "reddit" "toki pona" ];
        }
        {
          url = "https://one-button.org/feeds/articles.atom.xml";
          tags = [ "blog" ];
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
          url = "http://john.ankarstrom.se/desktop/feed/";
          tags = [ "blog" "computer" ];
        }
        {
          url = "http://john.ankarstrom.se/articles.xml";
          tags = [ "blog" "computer" ];
        }
        {
          url = "https://jcs.org/rss";
          tags = [ "blog" "computer" "OpenBSD" ];
        }
        {
          url = "https://rnd.neocities.org/blog/main.rss";
          title = "jan Lentan";
          tags = [ "blog" "toki pona" ];
        }
        {
          url = "https://hisham.hm/?x=feed:rss2&category=1";
          title = "hisham.hm";
          tags = [ "blog" ];
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

        # Aggregators
        {
          url = "https://tilde.news/rss";
          tags = [ "aggregators" ];
        }
        {
          url = "https://discourse.nixos.org/c/links/12.rss";
          tags = [ "aggregators" "NixOS" ];
        }


        # News
        {
          url = "https://lwn.net/headlines/newrss";
          tags = [ "news" "computer" ];
        }
        {
          url = "https://www.currentaffairs.org/feed";
          tags = [ "news" ];
        }
        {
          url = "https://theappalachianonline.com/feed/";
          title = "The Appalachian";
          tags = [ "news" "Appalachian State University" "Boone, NC" ];
        }
        {
          url = "https://www.wataugademocrat.com/search/?f=rss&t=article&c=news/local&l=50&s=start_time&sd=desc";
          title = "Watauga Democrat: local news";
          tags = [ "news" "Boone, NC" ];
        }
        {
          url = "https://www.wataugademocrat.com/search/?f=rss&t=article&c=news/asu_news&l=50&s=start_time&sd=desc";
          title = "Watauga Democrat: Appalachian State University news";
          tags = [ "news" "Appalachian State University" "Boone, NC" ];
        }
        {
          url = "https://wataugaonline.com/feed/";
          title = "Watauga Online";
          tags = [ "news" "Boone, NC" ];
        }
        {
          url = "https://feeds.feedburner.com/HCPress";
          title = "High Country Press";
          tags = [ "news" "Boone, NC" ];
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

        # OpenStreetMap
        {
          url = "\"exec:${discardContent} https://www.weeklyosm.eu/feed\"";
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
          tags = [ "OpenStreetMap" ];
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

        # Journals
        {
          url = "https://www.cambridge.org/core/rss/product/id/F3D70AB528A9726BC052F1AEB771A611";
          title = "Hypatia";
          tags = [ "journal" "philosophy" ];
        }
        # TODO: Does Duke University Press have a feed for Transgender Studies Quarterly?

        # System
        { url = "https://nixos.org/blog/announcements-rss.xml"; tags = [ "computer" "NixOS" ]; }
        { url = "exec:${generateNews}/bin/generate-news"; tags = [ "computer" "NixOS" ]; }

        # YouTube
        {
          url = "https://www.youtube.com/feeds/videos.xml?channel_id=UCXnNibvR_YIdyPs8PZIBoEw";
          title = "Cathode Ray Dude";
          tags = [ "YouTube" "tech" ];
        }
        { url = "https://www.youtube.com/feeds/videos.xml?channel_id=UCqdUXv9yQiIhspWPYgp8_XA"; }
        { url = "https://www.youtube.com/feeds/videos.xml?channel_id=UC18ju52OET36bdewLRHzPdQ"; }
        { url = "https://www.youtube.com/feeds/videos.xml?channel_id=UCy0tKL1T7wFoYcxCe0xjN6Q"; }
        { url = "https://www.youtube.com/feeds/videos.xml?channel_id=UClRwC5Vc8HrB6vGx6Ti-lhA"; }
        { url = "https://www.youtube.com/feeds/videos.xml?channel_id=UCW5OrUZ4SeUYkUg1XqcjFYA"; }

        # Toki Pona
        {
          url = "https://feeds.redcircle.com/901407e0-53e9-4aa2-aa3d-509393d10783";
          title = "kalama sin";
          tags = [ "podcast" "toki pona" ];
        }
        {
          url = "https://jonathangabel.com/feed.xml";
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
          tags = [ "toki pona" "blog" ];
        }
        {
          title = "GitHub: timeline";
          url =
            let
              generate = pkgs.writeShellScript "generate" ''
                ${config.programs.password-store.package}/bin/pass \
                    www/github.com/somasis.private.atom \
                    | ${pkgs.coreutils}/bin/tr -d '\n' \
                    | ${curl} -Lf -G --data-urlencode "token@-" "https://github.com/somasis.private.atom"
              '';
            in
            "exec:${generate}";
          tags = [ "notification" ];
        }
        # {
        #   url = ''"exec:${generateRedacted} https://redacted.ch/feeds.php?feed=feed_news"'';
        #   title = "Redacted: news";
        #   tags = [ "redacted" ];
        # }
        # {
        #   url = ''"exec:${generateRedacted} https://redacted.ch/feeds.php?feed=feed_blog"'';
        #   title = "Redacted: blog";
        #   tags = [ "redacted" ];
        # }
        {
          url = "https://www.wataugademocrat.com/classifieds/?f=rss&s=start_time&sd=asc";
          title = "Watauga Democrat: classifieds";
          tags = [ "Boone, NC" ];
        }
        {
          url = "https://www.townofboone.net/RSSFeed.aspx?ModID=63&CID=All-0";
          title = "Town of Boone: alerts";
          tags = [ "notification" ];
        }
        {
          url = "https://www.exploreboone.com/event/rss/";
          title = "Explore Boone: events";
          tags = [ "Boone, NC" ];
        }
      ];
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
        RandomizedDelaySec = "5m";
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

        <"$QUTE_HTML" \
            ${pkgs.sfeed}/bin/sfeed_web "$1" \
            | dmenu -p "qutebrowser [feeds]:" \
            | cut -f1 \
            | ${pkgs.xclip}/bin/xclip -i -selection clipboard

        ${pkgs.libnotify}/bin/notify-send \
            -a qute-feeds \
            -i application-rss+xml \
            -u low \
            qute-feeds \
            "Copied feed to clipboard."
      '';
    in
    "spawn -u ${quteFeeds} {url:domain}";
}

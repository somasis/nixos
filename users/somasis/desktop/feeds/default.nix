{ config
, nixosConfig
, lib
, pkgs
, ...
}:
let
  inherit (nixosConfig.services) tor;
  userAgent = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/97.0.4692.99 Safari/537.36";

  inherit (builtins) toString;
  inherit (pkgs) writeShellScript;
  inherit (lib)
    catAttrs
    concatLists
    concatStringsSep
    escape
    foldr
    getBin
    makeBinPath
    optionalString
    unique
    ;

  inherit (config.lib.somasis) feeds;
in
{
  imports = [
    ./aggregators.nix
    ./home-manager.nix
    ./redacted.nix
    # ./yt-dlp.nix
  ];

  programs.newsboat = {
    enable = true;

    maxItems = 10000;

    browser = toString (writeShellScript "newsboat-browser" ''
      ${pkgs.coreutils}/bin/nohup ${pkgs.xdg-utils}/bin/xdg-open "$1" >/dev/null 2>&1 &
    '');

    extraConfig =
      let
        newsboatHTMLRenderer = writeShellScript "newsboat-html-renderer" ''
          ${pkgs.rdrview}/bin/rdrview \
              -T body \
              -H "$@" \
              | ${pkgs.html-tidy}/bin/tidy \
                  -q \
                  -asxml \
                  -w 0 2>/dev/null \
              | ${pkgs.w3m-batch}/bin/w3m \
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

        # newsboat(1): "Configure a high number to keep the selected item in the center"
        scrolloff 100000
        
        show-keymap-hint no

        text-width 100

        cache-file "${config.xdg.cacheHome}/newsboat/cache.db"

        html-renderer "${newsboatHTMLRenderer}"
        user-agent "${userAgent}"
      ''
      # + optionalString (tor.enable && tor.client.enable) ''
      #   # socks5h: "CURLPROXY_SOCKS5_HOSTNAME [...] Proxy resolves URL hostname."
      #   use-proxy yes
      #   proxy ${tor.client.socksListenAddress.addr}:${toString tor.client.socksListenAddress.port}
      #   proxy-type socks5h
      #   download-timeout 60
      # ''
    ;

    # Create a list of queries from all URLs' tags.
    queries = { "!!! unread" = ''unread = "yes"''; }
      // (foldr (a: b: a // b) { } (
      map (x: { "... ${x}" = ''tags # "${x}"''; }) (unique (concatLists (catAttrs "tags" config.programs.newsboat.urls)))));

    urls = [
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
      {
        url = "https://wizardzines.com/comics/index.xml";
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
      {
        url = feeds.urls.filter "https://www.phoronix.com/rss.php" feeds.filters.discardContent;
        tags = [ "computer" "linux" ];
      }
      {
        url = "https://planet.nixos.org/atom.xml";
        tags = [ "computer" "NixOS" "blog" ];
        title = "Planet NixOS";
      }
      {
        url = "https://frame.work/blog.rss";
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
        tags = [ "review" "music" ];
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
        tags = [ "news" "local" ];
      }
      {
        url = "https://www.townofboone.net/RSSFeed.aspx?ModID=63&CID=All-0";
        title = "Town of Boone: alerts";
        tags = [ "notification" "local" ];
      }
      {
        url = "https://www.exploreboone.com/event/rss/";
        title = "Explore Boone: events";
        tags = [ "events" "local" ];
      }
      {
        url = "https://www.wataugademocrat.com/search/?f=rss&t=article&c=news/local&l=50&s=start_time&sd=desc";
        title = "Watauga Democrat: local";
        tags = [ "news" "local" ];
      }
      {
        url = "https://www.wataugademocrat.com/classifieds/?f=rss&s=start_time&sd=asc";
        title = "Watauga Democrat: classifieds";
        tags = [ "local" ];
      }
      {
        url = "https://www.wataugademocrat.com/search/?f=rss&t=article&c=news/asu_news&l=50&s=start_time&sd=desc";
        title = "Watauga Democrat: Appalachian State University";
        tags = [ "news" "local" ];
      }
      {
        url = "https://wataugaonline.com/feed/";
        title = "Watauga Online";
        tags = [ "news" "local" ];
      }
      {
        url = "https://feeds.feedburner.com/HCPress";
        title = "High Country Press";
        tags = [ "news" "local" ];
      }

      # Notifications
      {
        url = feeds.urls.secret "https://github.com/somasis.private.atom?token=%s" "www/github.com/somasis.private.atom";
        title = "GitHub: timeline";
        tags = [ "notification" "github" "computer" ];
      }

      # OpenStreetMap
      {
        url = feeds.urls.filter "https://www.weeklyosm.eu/feed" feeds.filters.discardContent;
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
        title = "OpenStreetMap: changes to review in Watauga County";
        tags = [ "notification" "OpenStreetMap" ];
      }
      {
        url = "https://resultmaps.neis-one.org/osm-suspicious-feed-bbox?hours=96&mappingdays=-1&tsearch=review_requested%3Dyes&anyobj=t&bbox=-80.7872772,35.1850329,-80.2963257,35.5093128";
        title = "OpenStreetMap: changes to review in Cabarrus County";
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

      {
        url = "https://drewdevault.com/blog/index.xml";
        tags = [ "blog" "development" "computer" ];
      }

      # Tumblr
      {
        url = "https://phidica.tumblr.com/rss";
        title = "Phidica";
        tags = [ "blog" "friends" "tumblr" ];
      }
      {
        url = "https://www.tumblr.com/rf9weu8hjf789234hf9";
        title = "rf9weu8hjf789234hf9";
        tags = [ "tumblr" ];
      }
      {
        url = "https://journcy.tumblr.com/rss";
        title = "Journcy";
        tags = [ "blog" "friends" "tumblr" ];
      }
      {
        url = "https://control--panel.com/rss";
        tags = [ "blog" "computer" "tumblr" ];
      }

      # System
      { url = "https://nixos.org/blog/announcements-rss.xml"; tags = [ "computer" "NixOS" ]; }


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

      {
        url = "https://www.urbanterror.info/rss/news/all";
        title = "Urban Terror: news";
        tags = [ "urbanterror" "games" ];
      }
      {
        url = "https://www.urbanterror.info/rss/blogs/all/";
        title = "Urban Terror: blogs";
        tags = [ "urbanterror" "blog" ];
      }
    ];
  };

  cache.directories = [{ method = "symlink"; directory = "var/cache/newsboat"; }];

  systemd.user = {
    services.feeds = {
      Unit = {
        Description = "Update feeds (if not during working hours)";
        StartLimitIntervalSec = 1;
        StartLimitBurst = 1;
        StartLimitAction = "none";
      };

      Service = {
        Type = "oneshot";
        ExecCondition = [
          "${pkgs.playtime}/bin/playtime -q"
          "${pkgs.writeShellScript ''newsboat-wait'' ''! ${pkgs.procps}/bin/pwait -u %u -x newsboat''}"
        ];
        ExecStart = [ "${pkgs.limitcpu}/bin/cpulimit -qf -l 25 -- ${pkgs.newsboat}/bin/newsboat -x reload" ];
        ExecStartPost = [ "-${pkgs.limitcpu}/bin/cpulimit -qf -l 25 -- ${pkgs.newsboat}/bin/newsboat --cleanup" ];

        Restart = "on-failure";
        RestartSec = 15;

        Nice = 19;
        CPUSchedulingPolicy = "idle";
        IOSchedulingClass = "idle";
        IOSchedulingPriority = 7;
      };
    };

    timers.feeds = {
      Unit = {
        Description = "Update feeds every two hours";
        PartOf = [ "default.target" ];
      };
      Install.WantedBy = [ "default.target" ];

      Timer = {
        OnCalendar = "0/2:00:00";
        OnUnitActiveSec = "2h";
        OnStartupSec = 0;
        Persistent = true;
        RandomizedDelaySec = "5m";
      };
    };
  };

  programs.qutebrowser = {
    aliases."feeds" =
      let
        quteFeeds = writeShellScript "qutebrowser-feeds" ''
          PATH=${makeBinPath [ pkgs.dmenu pkgs.coreutils pkgs.moreutils pkgs.sfeed pkgs.xclip ]}:$PATH

          : "''${QUTE_FIFO:?}"
          : "''${QUTE_HTML:?}"

          feeds=$(<"$QUTE_HTML" sfeed_web "$1" | cut -f1)

          if [[ -n "$feeds" ]]; then
              feeds=$(dmenu -l 4 -g 2 -p "qutebrowser [feeds]:" <<<"$feeds")
              xclip -selection clipboard -i <<< "$feeds"

              printf 'message-info "%s"\n' \
                  "feeds: copied feed to clipboard." \
                  > "''${QUTE_FIFO}"
          else
              printf 'message-warning "%s"\n' \
                  "feeds: no feeds were found." \
                  > "''${QUTE_FIFO}"
          fi
        '';
      in
      "spawn -u ${quteFeeds} {url:domain}";

    keyBindings.normal."zpf" = "feeds";
  };
}
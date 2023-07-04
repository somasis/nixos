{ pkgs
, options
, config
, lib
, inputs
, ...
}:
let
  nix-filter = inputs.nix-filter.lib;

  loujine-musicbrainz = pkgs.symlinkJoin {
    name = "loujine-musicbrainz";

    paths = [
      (nix-filter {
        root = pkgs.fetchFromGitHub {
          owner = "loujine";
          repo = "musicbrainz-scripts";
          rev = "417dcdbff16f5e06d5d3f590549d559c34adb905";
          hash = "sha256-nJ26J2QZRG4HMIo7GM++vLLCQX+I0RoONykuGY6UHJA=";
        };
        include = [ (nix-filter.matchExt "js") ];
      })
    ];
  };

  murdos-musicbrainz = pkgs.symlinkJoin {
    name = "murdos-musicbrainz";

    paths = [
      (nix-filter {
        root = pkgs.fetchFromGitHub {
          owner = "murdos";
          repo = "musicbrainz-userscripts";
          rev = "a7139415ba3ffd55ec22f3af91cd8ec9b592ed36";
          hash = "sha256-7torWVYJuUqDDjxjHuVbu+Ku5q0V1Sb3m/OIwbf6HvE=";
        };
        include = [ (nix-filter.matchExt "js") ];
      })
    ];
  };
in
lib.mkIf (options.programs.qutebrowser ? greasemonkey) {
  cache.directories = [ "share/qutebrowser/greasemonkey/requires" ];

  programs.qutebrowser.greasemonkey = map (x: if ! lib.isDerivation x then pkgs.writeText "${builtins.baseNameOf x}.user.js" (builtins.readFile x) else x) [
    # Global
    ((pkgs.fetchFromGitHub { owner = "navchandar"; repo = "Auto-Load-Big-Image"; rev = "ee388af4bb244bf34a6b24319f2c7bd72a8f3ccd"; hash = "sha256-DL7cIc+1iipl8CxamOsQQL7UpiAMhm62f8ok+r15wJw="; }) + "/Userscript.user.js")
    ((pkgs.fetchFromGitHub { owner = "eight04"; repo = "select-text-inside-a-link-like-opera"; rev = "3692b6a626e83cd073485dcee9929f80a52c10c9"; hash = "sha256-u5LpbuprShZKHNhw7RnNITfo1gM9pYDzSLHNI+CUYMk="; }) + "/select-text-inside-a-link-like-opera.user.js")
    (pkgs.fetchurl { hash = "sha256-R+1ZM05ZJgNUskjnmo0mtYMH3gPEldTNfBaMc5t5t3Y="; url = "https://gist.githubusercontent.com/oxguy3/ebd9fe692518c7f7a1e9/raw/234f5667d97e6a14fe47ef39ae45b6e5d5ebaf46/RoughScroll.js"; })

    ./rewrite-smolweb.user.js
    ./recaptcha-unpaid-labor.user.js

    # <https://adsbypasser.github.io/>
    (pkgs.fetchurl { hash = "sha256-+HDTlu5/WmuXI7vqNDi9XuQ5RvzHXaAf8fK7x3XxEp0="; url = "https://adsbypasser.github.io/releases/adsbypasser.full.es7.user.js"; })

    (pkgs.fetchurl { hash = "sha256-4nDL4vPOki+qpQmCKqLEVUc1Bh0uO3eJ8OpB8CuhJgs="; url = "https://greasyfork.org/scripts/32-show-password-onmouseover/code/Show%20Password%20onMouseOver.user.js"; })
    (pkgs.fetchurl { hash = "sha256-FshnFfKDwdCAam4Ikq0GlYcoJ0/a7B5vs8QMytLTqig="; url = "https://openuserjs.org/install/SelaoO/Ctrl+Enter_is_submit_everywhere.user.js"; })

    (pkgs.fetchurl { hash = "sha256-jDHXF0tV5yVACfwdMrRl65Ihl7SG/Xs+0WrNywseB0g="; url = "https://userscripts.adtidy.org/release/disable-amp/1.0/disable-amp.user.js"; })

    # <https://github.com/AdguardTeam/AdGuardExtra#adguard-extra>
    (pkgs.fetchurl { hash = "sha256-UymMfIN+7RhGNTHc+DgQkUDT/sXOtGvs61mT44x/7dg="; url = "https://userscripts.adtidy.org/release/adguard-extra/1.0/adguard-extra.user.js"; })

    (pkgs.fetchurl { hash = "sha256-F63/UXvFhBmcgHcoh4scOLqVgKdj+CjssIGnn3CshpU="; url = "https://greasyfork.org/scripts/4255-linkify-plus-plus/code/Linkify%20Plus%20Plus.user.js"; })

    ((pkgs.fetchFromGitHub { owner = "daijro"; repo = "always-on-focus"; rev = "106714a3e4f3a2b895dafd10e806939acfe87198"; hash = "sha256-N6dWry8YaZfBxEpqZPH8xIH7jhNcqevYVOxVtEVNodc="; }) + "/alwaysonfocus.user.js")

    (pkgs.runCommand "ISO-8601-dates.user.js"
      {
        src = (pkgs.fetchFromGitHub {
          owner = "chocolateboy";
          repo = "userscripts";
          rev = "bf1be5ea11f28b353457e809764d02617070dc82";
          hash = "sha256-DSCPThX/mOqhPYqfFx0xn5mJ4/CZEJGj0nd7He3Dcfc=";
        }) + "/src/iso_8601_dates.user.js";
      } ''sed '/^\/\/ @exclude/ i // @match *' "$src" > "$out"''
    )

    # musicbrainz.com
    # loujine-musicbrainz
    # murdos-musicbrainz
    # (pkgs.fetchurl { hash = "sha256-XfhDiCzTGG6IABLG+BnTWZkzCAwTIIqpGNKT30KaKj8="; url = "https://raw.githubusercontent.com/jesus2099/konami-command/master/mb_AUTO-FOCUS-KEYBOARD-SELECT.user.js"; })
    # (pkgs.fetchurl { hash = "sha256-a6n6Ne6U1LOrnAFjWFtQuVugrLHJSQkED9i7Jm4VqZs="; url = "https://raw.githubusercontent.com/jesus2099/konami-command/master/mb_REDIRECT-WHEN-UNIQUE-RESULT.user.js"; })
    # (pkgs.fetchurl { hash = "sha256-mofYLb+YQcY9knApTev869CMnFes1sPpSj39aY8DWrs="; url = "https://raw.githubusercontent.com/jesus2099/konami-command/master/mb_ELEPHANT-EDITOR.user.js"; })

    # bandcamp.com
    (pkgs.fetchurl { hash = "sha256-4NNDhOo9yyessyjmEMk3Znz0aRZgA+wtQw+JaUuD+iE="; url = "https://greasyfork.org/scripts/423498-bandcamp-extended-album-history/code/Bandcamp%20extended%20album%20history.user.js"; })
    (pkgs.fetchurl { hash = "sha256-bCMCQje8YBgjLXPzAgFvFo/MTzsE4JkdkZHjIW4C9hg="; url = "https://greasyfork.org/scripts/38012-bandcamp-volume-bar/code/Bandcamp%20Volume%20Bar.user.js"; })

    # redacted.ch
    (pkgs.fetchurl { hash = "sha256-ToKUcsKwyEYUccC1zQQurJ8iTB8mfAGSiJbvk0f6sF8="; url = "https://greasyfork.org/scripts/2140-redacted-ch-extended-main-menu/code/RedactedCH%20::%20Extended%20Main%20Menu.user.js"; })
    (pkgs.fetchurl { hash = "sha256-CeDotDjzjD4PcJ603NK1WCFw412wChZW5fcOjCg+4cI="; url = "https://greasyfork.org/scripts/395736-is-it-down/code/Is%20it%20Down.user.js"; })
    (pkgs.fetchurl { hash = "sha256-eh7QPO2vxP0rcaEL1Z+mso6yGX36jsQpwYU02UCXNTw="; url = "https://gitlab.com/_mclovin/purchase-links-for-music-requests/-/raw/1aa5621357a8b527ae75a5deef03367030b929e4/request-external-links.user.js"; })
    ./redacted-collapse-collages.js

    ((pkgs.fetchFromGitHub { owner = "SavageCore"; repo = "yadg-pth-userscript"; rev = "342d3bc58ee90be94b9829f5a6229b5c7f5d513b"; hash = "sha256-0cxt3fl1yRsU0NCmXAF51E6jVXImBX++8KcaFlRgPKQ="; }) + "/pth_yadg.meta.js")

    # github.com
    ((pkgs.fetchFromGitHub { owner = "devxoul"; repo = "github-monospace-editor"; rev = "90574105330c6ef66006d1e3c1d22779521da687"; hash = "sha256-0Ref63oUT+59B+i1RnCiq7TrhJZWJ6ka2oEFsYiebmA="; }) + "/script/github-monospace-editor.user.js")

    # news.ycombinator.com
    (pkgs.fetchurl { hash = "sha256-B8Po//yloy6fZfwlUsmNjWkwUV2IkTHBzc7TXu+E44c="; url = "https://greasyfork.org/scripts/39311-hacker-news-highlighter/code/Hacker%20News%20Highlighter.user.js"; })
    (pkgs.fetchurl { hash = "sha256-S2c6egARy9hxejN6Ct/zshUT/sWr9w6+LMfrRnVsDw0="; url = "https://greasyfork.org/scripts/23432-hacker-news-date-tooltips/code/Hacker%20News%20Date%20Tooltips.user.js"; })
    ((pkgs.fetchFromGitHub { owner = "hjk789"; repo = "Userscripts"; rev = "00c6934afc078167f180d84f63e0c5db443c8377"; hash = "sha256-1oUSbBrXN4M3WIGZztE/HwpZdf/O2aK1ROGzRARQvFg="; }) + "/Collapse-HackerNews-Parent-Comments/Collapse-HackerNews-Parent-Comments.user.js")

    # imdb.com
    (pkgs.fetchurl { hash = "sha256-+ZKq++Vd97Kn/Z37Se5gyVFqYsXepyQrWPzD/TG+Luk="; url = "https://greasyfork.org/scripts/23433-imdb-full-summary/code/IMDb%20Full%20Summary.user.js"; })
    (pkgs.fetchurl { hash = "sha256-8aOU00t2Dyw9iiFWYNnVS8Z130jnCrC1QIB2YQGKYY8="; url = "https://greasyfork.org/scripts/15222-imdb-tomatoes/code/IMDb%20Tomatoes.user.js"; })

    # google.com
    (pkgs.fetchurl { hash = "sha256-azHAQKmNxAcnyc7l08oW9X6DuMqAblFGPwD8T9DsrSs="; url = "https://greasyfork.org/scripts/32635-disable-google-search-result-url-redirector/code/Disable%20Google%20Search%20Result%20URL%20Redirector.user.js"; })
    (pkgs.fetchurl { hash = "sha256-Bb1QsU6R9xU718hRskGbuwNO7rrhuV7S1gvKtC9SlL0="; url = "https://greasyfork.org/scripts/37166-add-site-search-links-to-google-search-result/code/Add%20Site%20Search%20Links%20To%20Google%20Search%20Result.user.js"; })
    (pkgs.fetchurl { hash = "sha256-5C7No5dYcYfWMY+DwciMeBmkdE/wnplu5fxk4q7OFZc="; url = "https://greasyfork.org/scripts/382039-speed-up-google-captcha/code/Speed%20up%20Google%20Captcha.user.js"; })
    ((pkgs.fetchFromGitHub { owner = "jmlntw"; repo = "google-search-sidebar"; rev = "0e8e94c017681447cd9a21531d4cab7427f44022"; hash = "sha256-6bRzZTXYnAIsWJZQqfgmxdzeQOVk6H5swbCduCkqqIw="; }) + "/dist/google-search-sidebar.user.js")
    (pkgs.fetchurl { hash = "sha256-r4UF6jr3jhVP7JxJNPBzEpK1fkx5t97YWPwf37XLHHE="; url = "https://greasyfork.org/scripts/383166-google-images-search-by-paste/code/Google%20Images%20-%20search%20by%20paste.user.js"; })
    (pkgs.fetchurl { hash = "sha256-O+CuezLYKcK2Qh4jq4XxrtEEIPKOaruHnUGQNwkkCF8="; url = "https://greasyfork.org/scripts/381497-reddit-search-on-google/code/Reddit%20search%20on%20Google.user.js"; })

    (pkgs.fetchurl { hash = "sha256-/5Dub8dgql6z1p4PzK20Y9Yzb55Scjc6X97QaXIATTY="; url = "https://greasyfork.org/scripts/398189-google-image-direct-view/code/Google%20Image%20Direct%20View.user.js"; })

    # twitter.com
    # ((pkgs.fetchFromGitHub { owner = "yuhaofe"; repo = "Video-Quality-Fixer-for-Twitter"; rev = "704f5e4387835b95cb730838ae1df97bebe928dc"; hash = "sha256-oePFTou+Ho29458k129bPcPHmHyzsr0gfrH1H3Yjnpw="; }) + "/vqfft.user.js")
    # (pkgs.fetchurl { hash = "sha256-lyh/E3QfdLVDppPxVlPGKUBMR58ekojQ46v+J8A+DK4="; url = "https://gist.githubusercontent.com/angeld23/b01dd2ef14cd53fc3735fa88f68b7aef/raw/ee9c8df88b32e48249f3852011f2915bfa123f11/remove_twitter_blue_promo.user.js"; })
    (pkgs.fetchurl { hash = "sha256-3WED6Kodom4j27CDr7CBtdPFXBdRUf41iQk/O/Lkaz4="; url = "https://greasyfork.org/scripts/404632-twitter-direct/code/Twitter%20Direct.user.js"; })
    # (pkgs.fetchurl { hash = "sha256-/bkWrnzxoG9fHnj1t7Nbr0nFLoyovQAEXkgd/ZuBu1M="; url = "https://greasyfork.org/scripts/405103-twitter-linkify-trends/code/Twitter%20Linkify%20Trends.user.js"; })
    # (pkgs.fetchurl { hash = "sha256-tNWUn4LQZxn3ehfSzJ6KFs7H41+I7V8o9773Ua5uQJE="; url = "https://greasyfork.org/scripts/413963-twitter-zoom-cursor/code/Twitter%20Zoom%20Cursor.user.js"; })
    # (pkgs.fetchurl { hash = "sha256-vVd6iKMCV1V5MazeKn8ksfsp7zVt55KOULgkIXt3lms="; url = "https://greasyfork.org/scripts/464506-twitter-advertiser-blocker/code/Twitter%20Advertiser%20Blocker.user.js"; })

    # tumblr.com
    (pkgs.fetchurl { hash = "sha256-ArfFzIPFoLIoFVpxKVu5JWOhgmVE58L47ljbcI4yksM="; url = "https://greasyfork.org/scripts/31593-tumblr-images-to-hd-redirector/code/Tumblr%20Images%20to%20HD%20Redirector.user.js"; })

    # lemmy.ml, etc.
    ((pkgs.fetchFromGitHub { owner = "soundjester"; repo = "lemmy_monkey"; rev = "779d5e2843f5fd7bcc399eb5b122d24be7295e23"; hash = "sha256-7ndLbmTt2baDlVKoCXRIdXtcqjK2S7KUf6kOld/5PBA="; }) + /old.reddit.compact.user.js)

    # lobste.rs
    (pkgs.fetchurl { hash = "sha256-CJyDG74QVsw5n4U1lztzymorZ96/P20ifQF+/PtJKMs="; url = "https://greasyfork.org/scripts/40906-lobsters-highlighter/code/Lobsters%20Highlighter.user.js"; })
    (pkgs.fetchurl { hash = "sha256-JuF4HlaN5udaDKAwCEJKdKKCggJloGAZkCptMXI0xys="; url = "https://greasyfork.org/scripts/392307-lobste-rs-open-in-new-tab/code/Lobsters%20Open%20in%20New%20Tab.user.js"; })

    # reddit.com
    (pkgs.fetchurl { hash = "sha256-R53piHtc6P0EKmR51PUgHimdfN9UgnIY65El9XKxJiI="; url = "https://greasyfork.org/scripts/39312-reddit-highlighter/code/Reddit%20Highlighter.user.js"; })

    # substack.com
    (pkgs.fetchurl { hash = "sha256-fOTbMhKEw7To5/CDPmnwj5oVGzrFOCPri+edxZodb9g="; url = "https://greasyfork.org/scripts/465222-substack-popup-dismisser/code/substack_popup_dismisser.user.js"; })

    # youtube.com
    (pkgs.fetchurl { hash = "sha256-6FK4x/rZA1BxWOmYLjVU4rEFqXHgpwAy0rYedQzza2g="; url = "https://greasyfork.org/scripts/370755-youtube-peek-preview/code/Youtube%20Peek%20Preview.user.js"; })
    (pkgs.fetchurl { hash = "sha256-pKxroIOn19WvcvBKA5/+ZkkA2YxXkdTjN3l2SLLcC0A="; url = "https://gist.githubusercontent.com/codiac-killer/87e027a2c4d5d5510b4af2d25bca5b01/raw/764a0821aa248ec4126b16cdba7516c7190d287d/youtube-autoskip.user.js"; })
    (pkgs.fetchurl { hash = "sha256-LnorSydM+dA/5poDUdOEZ1uPoAOMQwpbLmadng3qCqI="; url = "https://greasyfork.org/scripts/23329-disable-youtube-60-fps-force-30-fps/code/Disable%20YouTube%2060%20FPS%20(Force%2030%20FPS).user.js"; })

    (
      let
        version = "1.3.2";
      in
      pkgs.runCommandLocal "sb.js"
        {
          settings = lib.concatStringsSep "\n" (lib.mapAttrsToList (k: v: "const ${k} = ${builtins.toJSON v}") {
            categories = [ "sponsor" ];
            actionTypes = [ "skip" ];
            skipThreshold = [ 0.2 1 ];
            serverEndpoint = "https://sponsor.ajay.app";
            skipTracking = true;
            highlightKey = "Enter";
          });

          sb_nosettings =
            (pkgs.fetchFromGitHub {
              owner = "mchangrh";
              repo = "sb.js";
              rev = "v${version}";
              hash = "sha256-rRA4Djq47LwXhPTpIOMix0/fsHs9CDgQI0KQavcpw34";
            })
            + "/docs/sb-nosettings.min.js"
          ;
        }
        ''
          cat - $sb_nosettings <<EOF > $out
          // ==UserScript==
          // @name         sb.js userscript
          // @description  SponsorBlock userscript
          // @namespace    mchang.name
          // @homepage     https://github.com/mchangrh/sb.js
          // @icon         https://mchangrh.github.io/sb.js/icon.png
          // @version      ${version}
          // @license      LGPL-3.0-or-later
          // @match        https://www.youtube.com/watch*
          // @connect      sponsor.ajay.app
          // @grant        none
          // ==/UserScript==
          $settings
          EOF
        ''
    )
    ((pkgs.fetchFromGitHub { owner = "Anarios"; repo = "return-youtube-dislike"; rev = "5c73825aadb81b6bf16cd5dff2b81a88562b6634"; hash = "sha256-+De9Ka9MYsR9az5Zb6w4gAJSKqU9GwqqO286hi9bGYY="; }) + "/Extensions/UserScript/Return Youtube Dislike.user.js")

    # wikipedia.org / wikipesija.org
    ./mediawiki-anchors.js

    # zoom.us
    (pkgs.fetchurl { hash = "sha256-BWIOITDCDnbX2MCIcTK/JtqBaz4SU6nRu5f8WUbN8GE="; url = "https://openuserjs.org/install/clemente/Zoom_redirector.user.js"; })

    # mastodon.social
    (pkgs.runCommand "mastodon-larger-preview.user.js"
      {
        src = (pkgs.fetchFromGitHub {
          owner = "Frederick888";
          repo = "mastodon-larger-preview";
          rev = "e9005241dfd904373041fdb46d7bf932ac7492f0";
          hash = "sha256-1miMTG8H/lf0BqiKdt9fA9qDiuhHqUiswM5mDqu594s=";
        }) + "/main.user.js";
      } ''sed '/^\/\/ @match/ i // @match https://mastodon.social/*' "$src" > "$out"''
    )
    (pkgs.runCommand "mastodon-pixiv-preview.user.js"
      {
        src = (pkgs.fetchFromGitHub {
          owner = "Frederick888";
          repo = "mastodon-pixiv-preview";
          rev = "b2994b11d041c77945bb59d0ebfe7ceb2920c985";
          hash = "sha256-pglKBOl6WPF0JDWVyk/r6J8MB9RGt9x14cRFd3A0b1E=";
        }) + "/main.user.js";
      } ''sed '/^\/\/ @match/ i // @match https://mastodon.social/*' "$src" > "$out"''
    )
  ];
}

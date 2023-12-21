{ config
, pkgs
, lib
, inputs
, ...
}: {
  programs.qutebrowser.greasemonkey = map config.lib.somasis.drvOrPath [
    ./rewrite-smolweb.user.js

    # MyAnimeList
    # (pkgs.fetchurl { hash = "sha256-XXjb7HZYobnOfW5fj1LESXb5LRu0ILAqPzaosV7YhfE="; url = "https://greasyfork.org/scripts/445087-anime-recommendations-mal/code/Anime%20Recommendations%20-%20MAL.user.js"; })

    # GitHub
    ((pkgs.fetchFromGitHub { owner = "devxoul"; repo = "github-monospace-editor"; rev = "90574105330c6ef66006d1e3c1d22779521da687"; hash = "sha256-0Ref63oUT+59B+i1RnCiq7TrhJZWJ6ka2oEFsYiebmA="; }) + "/script/github-monospace-editor.user.js")

    # Reddit
    (pkgs.fetchurl { hash = "sha256-R53piHtc6P0EKmR51PUgHimdfN9UgnIY65El9XKxJiI="; url = "https://greasyfork.org/scripts/39312-reddit-highlighter/code/Reddit%20Highlighter.user.js"; })

    # Lobsters
    (pkgs.fetchurl { hash = "sha256-CJyDG74QVsw5n4U1lztzymorZ96/P20ifQF+/PtJKMs="; url = "https://greasyfork.org/scripts/40906-lobsters-highlighter/code/Lobsters%20Highlighter.user.js"; })
    (pkgs.fetchurl { hash = "sha256-JuF4HlaN5udaDKAwCEJKdKKCggJloGAZkCptMXI0xys="; url = "https://greasyfork.org/scripts/392307-lobste-rs-open-in-new-tab/code/Lobsters%20Open%20in%20New%20Tab.user.js"; })

    # Tumblr
    (pkgs.fetchurl { hash = "sha256-ArfFzIPFoLIoFVpxKVu5JWOhgmVE58L47ljbcI4yksM="; url = "https://greasyfork.org/scripts/31593-tumblr-images-to-hd-redirector/code/Tumblr%20Images%20to%20HD%20Redirector.user.js"; })

    # Lemmy
    ((pkgs.fetchFromGitHub { owner = "soundjester"; repo = "lemmy_monkey"; rev = "779d5e2843f5fd7bcc399eb5b122d24be7295e23"; hash = "sha256-7ndLbmTt2baDlVKoCXRIdXtcqjK2S7KUf6kOld/5PBA="; }) + /old.reddit.compact.user.js)

    # Facebook
    # (pkgs.fetchurl { hash = "sha256-2v6wiC5yvxvbTDwHrmdnNZjrYKbUXxMXp0qMyMp5EDk="; url = "https://greasyfork.org/scripts/375911-facebook-show-most-recent-posts-by-default/code/Facebook%20-%20Show%20Most%20Recent%20Posts%20by%20Default.user.js"; })
    (pkgs.fetchurl { hash = "sha256-AZQQZdkBoJZ95BrY21Fn/bJ7zOKOOOqQGbjA3QIj390="; url = "https://greasyfork.org/scripts/431970-fb-clean-my-feeds/code/FB%20-%20Clean%20my%20feeds.user.js"; })

    # Instagram
    (pkgs.fetchurl { hash = "sha256-XsWwuXYS5zp40N2ljn/QtxcaSwo1LnpUrqr463uBtRg="; url = "https://greasyfork.org/scripts/451541-instagram-video-controls/code/Instagram%20Video%20Controls.user.js"; })
    (pkgs.fetchurl { hash = "sha256-/5Dub8dgql6z1p4PzK20Y9Yzb55Scjc6X97QaXIATTY="; url = "https://greasyfork.org/scripts/398189-google-image-direct-view/code/Google%20Image%20Direct%20View.user.js"; })

    # Twitter
    ((pkgs.fetchFromGitHub { owner = "yuhaofe"; repo = "Video-Quality-Fixer-for-Twitter"; rev = "704f5e4387835b95cb730838ae1df97bebe928dc"; hash = "sha256-oePFTou+Ho29458k129bPcPHmHyzsr0gfrH1H3Yjnpw="; }) + "/vqfft.user.js")
    # (pkgs.fetchurl { hash = "sha256-lyh/E3QfdLVDppPxVlPGKUBMR58ekojQ46v+J8A+DK4="; url = "https://gist.githubusercontent.com/angeld23/b01dd2ef14cd53fc3735fa88f68b7aef/raw/ee9c8df88b32e48249f3852011f2915bfa123f11/remove_twitter_blue_promo.user.js"; })
    (pkgs.fetchurl { hash = "sha256-3WED6Kodom4j27CDr7CBtdPFXBdRUf41iQk/O/Lkaz4="; url = "https://greasyfork.org/scripts/404632-twitter-direct/code/Twitter%20Direct.user.js"; })
    # (pkgs.fetchurl { hash = "sha256-/bkWrnzxoG9fHnj1t7Nbr0nFLoyovQAEXkgd/ZuBu1M="; url = "https://greasyfork.org/scripts/405103-twitter-linkify-trends/code/Twitter%20Linkify%20Trends.user.js"; })
    # (pkgs.fetchurl { hash = "sha256-tNWUn4LQZxn3ehfSzJ6KFs7H41+I7V8o9773Ua5uQJE="; url = "https://greasyfork.org/scripts/413963-twitter-zoom-cursor/code/Twitter%20Zoom%20Cursor.user.js"; })
    # (pkgs.fetchurl { hash = "sha256-vVd6iKMCV1V5MazeKn8ksfsp7zVt55KOULgkIXt3lms="; url = "https://greasyfork.org/scripts/464506-twitter-advertiser-blocker/code/Twitter%20Advertiser%20Blocker.user.js"; })

    (pkgs.runCommandLocal "control-panel-for-twitter.user.js"
      {
        src = inputs.control-panel-for-twitter + "/script.js";
        patch = ./control-panel-for-twitter.patch;
      }
      ''${pkgs.patch}/bin/patch -p1 -i "$patch" -o "$out" "$src"''
    )

    # Mastodon
    (pkgs.runCommandLocal "mastodon-larger-preview.user.js"
      {
        src = (pkgs.fetchFromGitHub {
          owner = "Frederick888";
          repo = "mastodon-larger-preview";
          rev = "e9005241dfd904373041fdb46d7bf932ac7492f0";
          hash = "sha256-1miMTG8H/lf0BqiKdt9fA9qDiuhHqUiswM5mDqu594s=";
        }) + "/main.user.js";
      } ''sed '/^\/\/ @match/ i // @match https://mastodon.social/*' "$src" > "$out"''
    )
    (pkgs.runCommandLocal "mastodon-pixiv-preview.user.js"
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

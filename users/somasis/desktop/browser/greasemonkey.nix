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

  # TODO
  # mkUserstyle = file:
  #   let
  #     name = builtins.replaceStrings [ "\.user" "\.css" ] [ "" "" ] (file.name or "${builtins.toString file}");

  #     css = pkgs.runCommandLocal "formatted.css" { inherit file; } ''
  #       ${pkgs.nodePackages.prettier}/bin/prettier \
  #           --no-config \
  #           --no-editorconfig \
  #           --stdin-filepath=userstyle.css \
  #           < "$file" > "$out"
  #     '';

  #     # <https://github.com/stylish-userstyles/stylish/wiki/Valid-@-moz-document-rules>
  #     # <https://wiki.greasespot.net/Include_and_exclude_rules>
  #     metadata = pkgs.runCommandLocal "metadata.js" { inherit css; } ''
  #       set -x
  #       set -euo pipefail

  #       # Get style's bundled metadata
  #       sed -En \
  #           -e '
  #               /^\/\* ==UserStyle==/,/^==\/UserStyle== \*\// {
  #                   /^\/\* ==UserStyle==/b
  #                   /^==\/UserStyle== \*\//b
  #                   s|^|// |p
  #               }
  #           ' \
  #           "$css" > "$out"

  #       # Convert @-moz-document rules to Greasemonkey @include rules
  #       sed -E \
  #           -e 's/^ *//' \
  #           -e '/@-moz-document\s/!d' \
  #           -e 's/ *\{$//' \
  #           -e 's/\), /)\n/g' \
  #           -e 's/;$//' \
  #           -e 's/^@-moz-document\s*//' \
  #           "$css" \
  #           | sed -E \
  #               -e '/^(domain|url|url-prefix|regexp)\((.+)\)$/!d' \
  #               -e '/^domain\(/ {
  #                   s/^domain\("?//
  #                   s/"?\)$//
  #                   s|^(.*)$|// @include *://\1/*\n// @include *://\*.\1/*|
  #               }' \
  #               -e '/^url\(/ {
  #                   s/^url\("?//
  #                   s/"?\)$//
  #                   s|^(.*)$|// @include \1|
  #               }' \
  #               -e '/^url-prefix\(/ {
  #                   s/^url-prefix\("?//
  #                   s/"?\)$//
  #                   s|^(.*)$|// @include \1*|
  #               }' \
  #               -e '/^regexp\(/ {
  #                   s/^regexp\("?//
  #                   s/"?\)$//
  #                   s|^(.*)$|// @include /\1/|
  #               }' \
  #           | sed '/^$/d' >> "$out"
  #     '';

  #     style = pkgs.runCommandLocal "style.css" { inherit css; } ''
  #       set -x
  #       set -euo pipefail

  #       sed \
  #           '/^@-moz-document .*{/,/^}/ { /^@-moz-document .*{/d; $d; }' \
  #           "$css" \
  #           | ${pkgs.minify}/bin/minify --type css > "$out"
  #     '';
  #   in
  #   pkgs.writeText "userstyle-${name}.user.js" ''
  #     // ==UserScript==
  #     ${builtins.readFile metadata}
  #     // @grant GM_addStyle
  #     // ==/UserScript==
  #     GM_addStyle(${builtins.toJSON (builtins.readFile style)});
  #   '';
in
lib.mkIf (options.programs.qutebrowser ? greasemonkey) {
  cache.directories = [ "share/qutebrowser/greasemonkey/requires" ];

  programs.qutebrowser.greasemonkey = [
    # Global
    (pkgs.fetchurl { hash = "sha256-PhyOl2bxQhJ9bNQboPYQf9J+87AxIUpEcz1wu5KzE/k="; url = "https://raw.githubusercontent.com/navchandar/Auto-Load-Big-Image/8fff139d89617697a2f83f92d62b8ca9df95e6f9/Userscript.user.js"; })
    (pkgs.fetchurl { hash = "sha256-jdjQw6tTOP5UZ26oYKRF6yNwN2WffzTRE18RMdBtB0U="; url = "https://raw.githubusercontent.com/eight04/select-text-inside-a-link-like-opera/v6.0.0/select-text-inside-a-link-like-opera.user.js"; })
    (pkgs.fetchurl { hash = "sha256-R+1ZM05ZJgNUskjnmo0mtYMH3gPEldTNfBaMc5t5t3Y="; url = "https://gist.githubusercontent.com/oxguy3/ebd9fe692518c7f7a1e9/raw/234f5667d97e6a14fe47ef39ae45b6e5d5ebaf46/RoughScroll.js"; })

    (pkgs.fetchurl { hash = "sha256-+HDTlu5/WmuXI7vqNDi9XuQ5RvzHXaAf8fK7x3XxEp0="; url = "https://adsbypasser.github.io/releases/adsbypasser.full.es7.user.js"; })
    (pkgs.fetchurl { hash = "sha256-4nDL4vPOki+qpQmCKqLEVUc1Bh0uO3eJ8OpB8CuhJgs="; url = "https://greasyfork.org/scripts/32-show-password-onmouseover/code/Show%20Password%20onMouseOver.user.js"; })
    (pkgs.fetchurl { hash = "sha256-FshnFfKDwdCAam4Ikq0GlYcoJ0/a7B5vs8QMytLTqig="; url = "https://openuserjs.org/install/SelaoO/Ctrl+Enter_is_submit_everywhere.user.js"; })
    (pkgs.fetchurl { hash = "sha256-jDHXF0tV5yVACfwdMrRl65Ihl7SG/Xs+0WrNywseB0g="; url = "https://userscripts.adtidy.org/release/disable-amp/1.0/disable-amp.user.js"; })

    # <https://userstyles.world/style/8283/unround-everything-everywhere>
    # (mkUserstyle (pkgs.fetchurl { hash = "sha256-mn1yXTdPvESPrabYrwXtp0Y5FiZKaNQ7+Lv19tZvY7U="; url = "https://userstyles.world/api/style/8283.user.css"; name = "unround-everything-everywhere.user.css"; }))

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
    (pkgs.writeText "redacted-collapse-collages.js" ./userscripts/redacted-collapse-collages.js)

    (pkgs.fetchurl { hash = "sha256-zJPLwo1nkpouG4Disb+egRKRAAC6d3lVaQP8JJl9uYE="; url = "https://raw.githubusercontent.com/SavageCore/yadg-pth-userscript/v1.9.0/pth_yadg.meta.js"; })

    # github.com
    (pkgs.fetchurl { hash = "sha256-jH2WsbtSIxlyMyVLD0r7i+yKczwpAV/7CEh+vrc6yuY="; url = "https://raw.githubusercontent.com/devxoul/github-monospace-editor/0.1.3/script/github-monospace-editor.user.js"; })

    # news.ycombinator.com
    (pkgs.fetchurl { hash = "sha256-B8Po//yloy6fZfwlUsmNjWkwUV2IkTHBzc7TXu+E44c="; url = "https://greasyfork.org/scripts/39311-hacker-news-highlighter/code/Hacker%20News%20Highlighter.user.js"; })
    (pkgs.fetchurl { hash = "sha256-S2c6egARy9hxejN6Ct/zshUT/sWr9w6+LMfrRnVsDw0="; url = "https://greasyfork.org/scripts/23432-hacker-news-date-tooltips/code/Hacker%20News%20Date%20Tooltips.user.js"; })

    # imdb.com
    (pkgs.fetchurl { hash = "sha256-+ZKq++Vd97Kn/Z37Se5gyVFqYsXepyQrWPzD/TG+Luk="; url = "https://greasyfork.org/scripts/23433-imdb-full-summary/code/IMDb%20Full%20Summary.user.js"; })
    (pkgs.fetchurl { hash = "sha256-8aOU00t2Dyw9iiFWYNnVS8Z130jnCrC1QIB2YQGKYY8="; url = "https://greasyfork.org/scripts/15222-imdb-tomatoes/code/IMDb%20Tomatoes.user.js"; })

    # google.com
    (pkgs.fetchurl { hash = "sha256-azHAQKmNxAcnyc7l08oW9X6DuMqAblFGPwD8T9DsrSs="; url = "https://greasyfork.org/scripts/32635-disable-google-search-result-url-redirector/code/Disable%20Google%20Search%20Result%20URL%20Redirector.user.js"; })
    (pkgs.fetchurl { hash = "sha256-Bb1QsU6R9xU718hRskGbuwNO7rrhuV7S1gvKtC9SlL0="; url = "https://greasyfork.org/scripts/37166-add-site-search-links-to-google-search-result/code/Add%20Site%20Search%20Links%20To%20Google%20Search%20Result.user.js"; })
    (pkgs.fetchurl { hash = "sha256-5C7No5dYcYfWMY+DwciMeBmkdE/wnplu5fxk4q7OFZc="; url = "https://greasyfork.org/scripts/382039-speed-up-google-captcha/code/Speed%20up%20Google%20Captcha.user.js"; })
    (pkgs.fetchurl { hash = "sha256-O7xInRO9H+AhG8Y6Ky5IDVJK++jzMHggSeq5X7/Je1A="; url = "https://raw.githubusercontent.com/jmlntw/google-search-sidebar/v0.4.1/dist/google-search-sidebar.user.js"; })

    # images.google.com
    (pkgs.fetchurl { hash = "sha256-lNGCdMjf5RsR/70T81VaW2S5w71PSK4pHwsaBTL6Gqg="; url = "https://greasyfork.org/scripts/29420-google-dwimages/code/Google%20DWIMages.user.js"; })

    # twitter.com
    (pkgs.fetchurl { hash = "sha256-JFBaqr7MDRwKbiGYm0b5YhcRhfkDWzg2Idf8N+U3pLs="; url = "https://raw.githubusercontent.com/yuhaofe/Video-Quality-Fixer-for-Twitter/v0.2.0/vqfft.user.js"; })
    # (pkgs.fetchurl { hash = "sha256-zQd4egcF4xOVEOJi8RKHSTzFfzrR3bBhHcT6tzIkmtc="; url = "https://greasyfork.org/scripts/387773-control-panel-for-twitter/code/Control%20Panel%20for%20Twitter.user.js"; })

    (pkgs.fetchurl { hash = "sha256-3WED6Kodom4j27CDr7CBtdPFXBdRUf41iQk/O/Lkaz4="; url = "https://greasyfork.org/scripts/404632-twitter-direct/code/Twitter%20Direct.user.js"; })
    (pkgs.fetchurl { hash = "sha256-/bkWrnzxoG9fHnj1t7Nbr0nFLoyovQAEXkgd/ZuBu1M="; url = "https://greasyfork.org/scripts/405103-twitter-linkify-trends/code/Twitter%20Linkify%20Trends.user.js"; })
    (pkgs.fetchurl { hash = "sha256-tNWUn4LQZxn3ehfSzJ6KFs7H41+I7V8o9773Ua5uQJE="; url = "https://greasyfork.org/scripts/413963-twitter-zoom-cursor/code/Twitter%20Zoom%20Cursor.user.js"; })
    (pkgs.fetchurl { hash = "sha256-vVd6iKMCV1V5MazeKn8ksfsp7zVt55KOULgkIXt3lms="; url = "https://greasyfork.org/scripts/464506-twitter-advertiser-blocker/code/Twitter%20Advertiser%20Blocker.user.js"; })

    # tumblr.com
    (pkgs.fetchurl { hash = "sha256-ArfFzIPFoLIoFVpxKVu5JWOhgmVE58L47ljbcI4yksM="; url = "https://greasyfork.org/scripts/31593-tumblr-images-to-hd-redirector/code/Tumblr%20Images%20to%20HD%20Redirector.user.js"; })

    # lobste.rs
    (pkgs.fetchurl { hash = "sha256-CJyDG74QVsw5n4U1lztzymorZ96/P20ifQF+/PtJKMs="; url = "https://greasyfork.org/scripts/40906-lobsters-highlighter/code/Lobsters%20Highlighter.user.js"; })
    (pkgs.fetchurl { hash = "sha256-JuF4HlaN5udaDKAwCEJKdKKCggJloGAZkCptMXI0xys="; url = "https://greasyfork.org/scripts/392307-lobste-rs-open-in-new-tab/code/Lobsters%20Open%20in%20New%20Tab.user.js"; })

    # reddit.com
    (pkgs.fetchurl { hash = "sha256-R53piHtc6P0EKmR51PUgHimdfN9UgnIY65El9XKxJiI="; url = "https://greasyfork.org/scripts/39312-reddit-highlighter/code/Reddit%20Highlighter.user.js"; })

    # youtube.com
    (pkgs.fetchurl { hash = "sha256-pKxroIOn19WvcvBKA5/+ZkkA2YxXkdTjN3l2SLLcC0A="; url = "https://gist.githubusercontent.com/codiac-killer/87e027a2c4d5d5510b4af2d25bca5b01/raw/764a0821aa248ec4126b16cdba7516c7190d287d/youtube-autoskip.user.js"; })
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
    (pkgs.fetchurl { hash = "sha256-5JC3vrPj+kJq68AFtEWwriyCc7sD8nIpqc6dLbjPGso="; url = "https://raw.githubusercontent.com/Anarios/return-youtube-dislike/main/Extensions/UserScript/Return%20Youtube%20Dislike.user.js"; })

    # wikipedia.org / wikipesija.org
    (pkgs.writeText "mediawiki-anchors.js" ./userscripts/mediawiki-anchors.js)

    # zoom.us
    (pkgs.fetchurl { hash = "sha256-BWIOITDCDnbX2MCIcTK/JtqBaz4SU6nRu5f8WUbN8GE="; url = "https://openuserjs.org/install/clemente/Zoom_redirector.user.js"; })

    # mastodon.social
    (pkgs.runCommand "mastodon-larger-preview.user.js"
      {
        src = pkgs.fetchurl {
          url = "https://raw.githubusercontent.com/Frederick888/mastodon-larger-preview/e9005241dfd904373041fdb46d7bf932ac7492f0/main.user.js";
          hash = "sha256-fI3FnflWfZu5dinktgOgvKMQr/MDhjoWcpu1dzLx7vQ=";
        };
      } ''sed '/^\/\/ @match/ i // @match https://mastodon.social/*' "$src" > "$out"''
    )
    (pkgs.runCommand "mastodon-pixiv-preview.user.js"
      {
        src = pkgs.fetchurl {
          url = "https://raw.githubusercontent.com/Frederick888/mastodon-pixiv-preview/b2994b11d041c77945bb59d0ebfe7ceb2920c985/main.user.js";
          hash = "sha256-t/lm/ydlkW/4Gl86rXdwrBWsMYvRMWHl9gJ0qCCs1Sw=";
        };
      } ''sed '/^\/\/ @match/ i // @match https://mastodon.social/*' "$src" > "$out"''
    )
  ];
}

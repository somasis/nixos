{ config
, pkgs
, lib
, ...
}: {
  cache.directories = [ "share/qutebrowser/greasemonkey/requires" ];

  imports = [
    # ./musicbrainz.nix
    ./search.nix
    ./social.nix
    ./video.nix
  ];

  programs.qutebrowser.greasemonkey = map config.lib.somasis.drvOrPath [
    # *

    # Automatically load higher quality versions of images.
    ((pkgs.fetchFromGitHub {
      owner = "navchandar";
      repo = "Auto-Load-Big-Image";
      rev = "ee388af4bb244bf34a6b24319f2c7bd72a8f3ccd";
      hash = "sha256-DL7cIc+1iipl8CxamOsQQL7UpiAMhm62f8ok+r15wJw=";
    }) + "/Userscript.user.js")

    # Allow for selecting link text by dragging.
    ((pkgs.fetchFromGitHub {
      owner = "eight04";
      repo = "select-text-inside-a-link-like-opera";
      rev = "3692b6a626e83cd073485dcee9929f80a52c10c9";
      hash = "sha256-u5LpbuprShZKHNhw7RnNITfo1gM9pYDzSLHNI+CUYMk=";
    }) + "/select-text-inside-a-link-like-opera.user.js")

    (pkgs.fetchurl {
      hash = "sha256-R+1ZM05ZJgNUskjnmo0mtYMH3gPEldTNfBaMc5t5t3Y=";
      url = "https://gist.githubusercontent.com/oxguy3/ebd9fe692518c7f7a1e9/raw/234f5667d97e6a14fe47ef39ae45b6e5d5ebaf46/RoughScroll.js";
    })

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

    # bandcamp.com
    (pkgs.fetchurl { hash = "sha256-4NNDhOo9yyessyjmEMk3Znz0aRZgA+wtQw+JaUuD+iE="; url = "https://greasyfork.org/scripts/423498-bandcamp-extended-album-history/code/Bandcamp%20extended%20album%20history.user.js"; })
    (pkgs.fetchurl { hash = "sha256-bCMCQje8YBgjLXPzAgFvFo/MTzsE4JkdkZHjIW4C9hg="; url = "https://greasyfork.org/scripts/38012-bandcamp-volume-bar/code/Bandcamp%20Volume%20Bar.user.js"; })

    # redacted.ch
    (pkgs.fetchurl { hash = "sha256-ToKUcsKwyEYUccC1zQQurJ8iTB8mfAGSiJbvk0f6sF8="; url = "https://greasyfork.org/scripts/2140-redacted-ch-extended-main-menu/code/RedactedCH%20::%20Extended%20Main%20Menu.user.js"; })
    (pkgs.fetchurl { hash = "sha256-CeDotDjzjD4PcJ603NK1WCFw412wChZW5fcOjCg+4cI="; url = "https://greasyfork.org/scripts/395736-is-it-down/code/Is%20it%20Down.user.js"; })
    (pkgs.fetchurl { hash = "sha256-eh7QPO2vxP0rcaEL1Z+mso6yGX36jsQpwYU02UCXNTw="; url = "https://gitlab.com/_mclovin/purchase-links-for-music-requests/-/raw/1aa5621357a8b527ae75a5deef03367030b929e4/request-external-links.user.js"; })
    ./redacted-collapse-collages.js

    ((pkgs.fetchFromGitHub { owner = "SavageCore"; repo = "yadg-pth-userscript"; rev = "342d3bc58ee90be94b9829f5a6229b5c7f5d513b"; hash = "sha256-0cxt3fl1yRsU0NCmXAF51E6jVXImBX++8KcaFlRgPKQ="; }) + "/pth_yadg.meta.js")

    # news.ycombinator.com
    (pkgs.fetchurl { hash = "sha256-B8Po//yloy6fZfwlUsmNjWkwUV2IkTHBzc7TXu+E44c="; url = "https://greasyfork.org/scripts/39311-hacker-news-highlighter/code/Hacker%20News%20Highlighter.user.js"; })
    (pkgs.fetchurl { hash = "sha256-S2c6egARy9hxejN6Ct/zshUT/sWr9w6+LMfrRnVsDw0="; url = "https://greasyfork.org/scripts/23432-hacker-news-date-tooltips/code/Hacker%20News%20Date%20Tooltips.user.js"; })
    ((pkgs.fetchFromGitHub { owner = "hjk789"; repo = "Userscripts"; rev = "00c6934afc078167f180d84f63e0c5db443c8377"; hash = "sha256-1oUSbBrXN4M3WIGZztE/HwpZdf/O2aK1ROGzRARQvFg="; }) + "/Collapse-HackerNews-Parent-Comments/Collapse-HackerNews-Parent-Comments.user.js")

    # imdb.com
    (pkgs.fetchurl { hash = "sha256-+ZKq++Vd97Kn/Z37Se5gyVFqYsXepyQrWPzD/TG+Luk="; url = "https://greasyfork.org/scripts/23433-imdb-full-summary/code/IMDb%20Full%20Summary.user.js"; })
    (pkgs.fetchurl { hash = "sha256-8aOU00t2Dyw9iiFWYNnVS8Z130jnCrC1QIB2YQGKYY8="; url = "https://greasyfork.org/scripts/15222-imdb-tomatoes/code/IMDb%20Tomatoes.user.js"; })

    # substack.com
    (pkgs.fetchurl { hash = "sha256-fOTbMhKEw7To5/CDPmnwj5oVGzrFOCPri+edxZodb9g="; url = "https://greasyfork.org/scripts/465222-substack-popup-dismisser/code/substack_popup_dismisser.user.js"; })

    # wikipedia.org / wikipesija.org
    ./mediawiki-anchors.js

    # zoom.us
    (pkgs.fetchurl { hash = "sha256-BWIOITDCDnbX2MCIcTK/JtqBaz4SU6nRu5f8WUbN8GE="; url = "https://openuserjs.org/install/clemente/Zoom_redirector.user.js"; })
  ];
}

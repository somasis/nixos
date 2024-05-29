{ config
, pkgs
, lib
, ...
}: {
  cache.directories = [ "share/qutebrowser/greasemonkey/requires" ];

  imports = [
    ./musicbrainz.nix
    ./social.nix
  ];

  programs.qutebrowser.greasemonkey = map config.lib.somasis.drvOrPath [
    ./anchor-links.user.js
    ./quirks.user.js

    ./recaptcha-unpaid-labor.user.js
    (pkgs.fetchurl { hash = "sha256-5C7No5dYcYfWMY+DwciMeBmkdE/wnplu5fxk4q7OFZc="; url = "https://greasyfork.org/scripts/382039-speed-up-google-captcha/code/Speed%20up%20Google%20Captcha.user.js"; })

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

    # <https://adsbypasser.github.io/>
    (pkgs.fetchurl { hash = "sha256-+HDTlu5/WmuXI7vqNDi9XuQ5RvzHXaAf8fK7x3XxEp0="; url = "https://adsbypasser.github.io/releases/adsbypasser.full.es7.user.js"; })

    (pkgs.fetchurl { hash = "sha256-4nDL4vPOki+qpQmCKqLEVUc1Bh0uO3eJ8OpB8CuhJgs="; url = "https://greasyfork.org/scripts/32-show-password-onmouseover/code/Show%20Password%20onMouseOver.user.js"; })
    (pkgs.fetchurl { hash = "sha256-FshnFfKDwdCAam4Ikq0GlYcoJ0/a7B5vs8QMytLTqig="; url = "https://openuserjs.org/install/SelaoO/Ctrl+Enter_is_submit_everywhere.user.js"; })

    (pkgs.fetchurl { hash = "sha256-jDHXF0tV5yVACfwdMrRl65Ihl7SG/Xs+0WrNywseB0g="; url = "https://userscripts.adtidy.org/release/disable-amp/1.0/disable-amp.user.js"; })

    # <https://github.com/AdguardTeam/AdGuardExtra#adguard-extra>
    (pkgs.fetchurl { hash = "sha256-UymMfIN+7RhGNTHc+DgQkUDT/sXOtGvs61mT44x/7dg="; url = "https://userscripts.adtidy.org/release/adguard-extra/1.0/adguard-extra.user.js"; })

    ((pkgs.fetchFromGitHub { owner = "daijro"; repo = "always-on-focus"; rev = "106714a3e4f3a2b895dafd10e806939acfe87198"; hash = "sha256-N6dWry8YaZfBxEpqZPH8xIH7jhNcqevYVOxVtEVNodc="; }) + "/alwaysonfocus.user.js")

    (pkgs.runCommandLocal "ISO-8601-dates.user.js"
      {
        src = (pkgs.fetchFromGitHub {
          owner = "chocolateboy";
          repo = "userscripts";
          rev = "bf1be5ea11f28b353457e809764d02617070dc82";
          hash = "sha256-DSCPThX/mOqhPYqfFx0xn5mJ4/CZEJGj0nd7He3Dcfc=";
        }) + "/src/iso_8601_dates.user.js";

        matches = [
          "https://phish.net/*"
        ];
      } ''
      ${pkgs.gnused}/bin/sed -E '
          /^\/\/ @exclude/ {
              r '<(printf '// @match %s\n' "''${matches[@]}")'
              d
          }' \
          "$src" > "$out"
    ''
    )

    # bandcamp.com
    (pkgs.fetchurl { hash = "sha256-4NNDhOo9yyessyjmEMk3Znz0aRZgA+wtQw+JaUuD+iE="; url = "https://greasyfork.org/scripts/423498-bandcamp-extended-album-history/code/Bandcamp%20extended%20album%20history.user.js"; })
    (pkgs.fetchurl { hash = "sha256-bCMCQje8YBgjLXPzAgFvFo/MTzsE4JkdkZHjIW4C9hg="; url = "https://greasyfork.org/scripts/38012-bandcamp-volume-bar/code/Bandcamp%20Volume%20Bar.user.js"; })

    # news.ycombinator.com
    (pkgs.fetchurl { hash = "sha256-B8Po//yloy6fZfwlUsmNjWkwUV2IkTHBzc7TXu+E44c="; url = "https://greasyfork.org/scripts/39311-hacker-news-highlighter/code/Hacker%20News%20Highlighter.user.js"; })
    (pkgs.fetchurl { hash = "sha256-S2c6egARy9hxejN6Ct/zshUT/sWr9w6+LMfrRnVsDw0="; url = "https://greasyfork.org/scripts/23432-hacker-news-date-tooltips/code/Hacker%20News%20Date%20Tooltips.user.js"; })
    ((pkgs.fetchFromGitHub { owner = "hjk789"; repo = "Userscripts"; rev = "00c6934afc078167f180d84f63e0c5db443c8377"; hash = "sha256-1oUSbBrXN4M3WIGZztE/HwpZdf/O2aK1ROGzRARQvFg="; }) + "/Collapse-HackerNews-Parent-Comments/Collapse-HackerNews-Parent-Comments.user.js")

    # imdb.com
    (pkgs.fetchurl { hash = "sha256-+ZKq++Vd97Kn/Z37Se5gyVFqYsXepyQrWPzD/TG+Luk="; url = "https://greasyfork.org/scripts/23433-imdb-full-summary/code/IMDb%20Full%20Summary.user.js"; })
    (pkgs.fetchurl { hash = "sha256-8aOU00t2Dyw9iiFWYNnVS8Z130jnCrC1QIB2YQGKYY8="; url = "https://greasyfork.org/scripts/15222-imdb-tomatoes/code/IMDb%20Tomatoes.user.js"; })

    # substack.com
    (pkgs.fetchurl { hash = "sha256-fOTbMhKEw7To5/CDPmnwj5oVGzrFOCPri+edxZodb9g="; url = "https://greasyfork.org/scripts/465222-substack-popup-dismisser/code/substack_popup_dismisser.user.js"; })

    # archive.org
    # <https://bookripper.neocities.org/>
    (pkgs.fetchurl { hash = "sha256-0RlBXvCr1+8m4VyBzvWxqipzNRpQZve77U8lKGE5TiI="; url = "https://bookripper.neocities.org/internetarchivebookripper.user.js"; })

    # zoom.us
    # (pkgs.fetchurl { hash = "sha256-BWIOITDCDnbX2MCIcTK/JtqBaz4SU6nRu5f8WUbN8GE="; url = "https://openuserjs.org/install/clemente/Zoom_redirector.user.js"; })
  ];
}

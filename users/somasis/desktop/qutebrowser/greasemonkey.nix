{ pkgs
, lib
, ...
}:
let
  #   mkScript =
  #     list:
  #     builtins.listToAttrs
  #       (
  #         builtins.map
  #           (
  #             attrs@{ url, hash, required ? false, name ? null }:
  #             let
  #               # Roughly implement qutebrowser's required-script-filename modification logic.
  #               finalName = (
  #                 if name == null then
  #                   lib.replaceStrings [ ".user.js" ".js" ] [ "" "" ] (builtins.split "\." script.name)
  #                 else
  #                   name
  #               );
  #             in
  #             attr // {
  #               xdg.dataFile."qutebrowser/greasemonkey/${if required then ''requires/'' else ''''}${finalName}";
  #               value.source = script;
  #             }
  #           )
  #           list
  #       )
  #   ;
  # mkScript = name: list: pkgs.linkFarm name
  #   (builtins.map
  #     (drv:
  #       { finalName ? drv.name, ... }: {
  #         name = finalName;
  #         path = "${drv}";
  #       }
  #     )
  #     list);
in
{
  programs.qutebrowser = {
    userScripts = [
      # Global
      (pkgs.fetchurl { url = "https://greasyfork.org/scripts/32-show-password-onmouseover/code/Show%20Password%20onMouseOver.user.js"; hash = "sha256-4nDL4vPOki+qpQmCKqLEVUc1Bh0uO3eJ8OpB8CuhJgs="; })
      (pkgs.fetchurl { url = "https://greasyfork.org/scripts/382482-assassinate-ad-block-blockers/code/Assassinate%20Ad%20Block%20Blockers.user.js"; hash = "sha256-4DiJWIdX7Awsf6SIBQ39GSoDjVd2ztDkvvZCDnVxRz4="; })
      (pkgs.fetchurl { url = "https://greasyfork.org/scripts/789-select-text-inside-a-link-like-opera/code/Select%20text%20inside%20a%20link%20like%20Opera.user.js"; hash = "sha256-jdjQw6tTOP5UZ26oYKRF6yNwN2WffzTRE18RMdBtB0U="; })
      (pkgs.fetchurl { url = "https://openuserjs.org/install/SelaoO/Ctrl+Enter_is_submit_everywhere.user.js"; hash = "sha256-FshnFfKDwdCAam4Ikq0GlYcoJ0/a7B5vs8QMytLTqig="; })
      (pkgs.fetchurl { url = "https://openuserjs.org/install/navchandar/Auto_Load_Big_Image.user.js"; hash = "sha256-byunLh6WroO0oz9F1s6d1KYEhKtqyCs7cfcymiFa6rQ="; })
      (pkgs.fetchurl { url = "https://userscripts.adtidy.org/release/disable-amp/1.0/disable-amp.user.js"; hash = "sha256-NHPpnOKKJ9VJ0k9AG83xgeh2fcJs95kXYRXV94vYBXg="; })
      (pkgs.fetchurl { url = "https://adsbypasser.github.io/releases/adsbypasser.full.es7.user.js"; hash = "sha256-HasztV3C8lC9trGAJwOMOymaTLfQfTTxoSbvh4S88F4="; })
      # { userscript = pkgs.fetchurl { url = "https://greasyfork.org/scripts/4255-linkify-plus-plus/code/Linkify%20Plus%20Plus.user.js"; hash = "sha256-F63/UXvFhBmcgHcoh4scOLqVgKdj+CjssIGnn3CshpU="; }; }

      # YouTube
      (pkgs.fetchurl { url = "https://gist.githubusercontent.com/codiac-killer/87e027a2c4d5d5510b4af2d25bca5b01/raw/youtube-autoskip.user.js"; hash = "sha256-pKxroIOn19WvcvBKA5/+ZkkA2YxXkdTjN3l2SLLcC0A="; })
      (pkgs.fetchurl { url = "https://greasyfork.org/scripts/418283-youtube-cpu-tamer/code/YouTube%20CPU%20Tamer.user.js"; hash = "sha256-4sidgnCqiIYSsgaO/7Qx+vRQBtdZqlsqjP5fAAxYmGE="; })
      (pkgs.fetchurl { url = "https://raw.githubusercontent.com/mchangrh/sb.js/main/docs/sb-loader.user.js"; hash = "sha256-YrJkz7lyn+NFdAW5GaLsWPhfHGBIY3UfHY0jqgvLNkg="; })

      # Google
      (pkgs.fetchurl { url = "https://greasyfork.org/scripts/29420-google-dwimages/code/Google%20DWIMages.user.js"; hash = "sha256-oWv3MKnx6NxWLOEOfLryhKM3vM8AGhf9SB4YuuLGlOw="; })
      (pkgs.fetchurl { url = "https://greasyfork.org/scripts/32635-disable-google-search-result-url-redirector/code/Disable%20Google%20Search%20Result%20URL%20Redirector.user.js"; hash = "sha256-azHAQKmNxAcnyc7l08oW9X6DuMqAblFGPwD8T9DsrSs="; })
      (pkgs.fetchurl { url = "https://greasyfork.org/scripts/37166-add-site-search-links-to-google-search-result/code/Add%20Site%20Search%20Links%20To%20Google%20Search%20Result.user.js"; hash = "sha256-l5qXH6yl5uXanDhHj+7A9WLLiDHdcQo+nhrbJQjWJZc="; })
      (pkgs.fetchurl { url = "https://greasyfork.org/scripts/382039-speed-up-google-captcha/code/Speed%20up%20Google%20Captcha.user.js"; hash = "sha256-5C7No5dYcYfWMY+DwciMeBmkdE/wnplu5fxk4q7OFZc="; })

      # Redacted
      (pkgs.fetchurl { url = "https://gitlab.com/_mclovin/purchase-links-for-music-requests/-/raw/master/request-external-links.user.js"; hash = "sha256-eh7QPO2vxP0rcaEL1Z+mso6yGX36jsQpwYU02UCXNTw="; })
      (pkgs.fetchurl { url = "https://greasyfork.org/scripts/2140-redacted-ch-extended-main-menu/code/RedactedCH%20::%20Extended%20Main%20Menu.user.js"; hash = "sha256-ToKUcsKwyEYUccC1zQQurJ8iTB8mfAGSiJbvk0f6sF8="; })
      (pkgs.fetchurl { url = "https://greasyfork.org/scripts/395736-is-it-down/code/Is%20it%20Down.user.js"; hash = "sha256-CeDotDjzjD4PcJ603NK1WCFw412wChZW5fcOjCg+4cI="; })
      (pkgs.fetchurl { url = "https://raw.githubusercontent.com/SavageCore/yadg-pth-userscript/master/pth_yadg.meta.js"; hash = "sha256-M02cD/Y+MmyEX06lTy06kgA0wNa3mKaLDxlVN9ehJqo="; })

      # IMDB
      (pkgs.fetchurl { url = "https://greasyfork.org/scripts/15222-imdb-tomatoes/code/IMDb%20Tomatoes.user.js"; hash = "sha256-QVLgFK9LW9ZyyjViyjMP/lS/RS0C8Xzj7idNUPI6vDc="; })
      (pkgs.fetchurl { url = "https://greasyfork.org/scripts/23433-imdb-full-summary/code/IMDb%20Full%20Summary.user.js"; hash = "sha256-xJx6cUDrQi+pmqqQ/8r84D4XC3425pXvbNQh1BaTlkg="; })

      # Hacker News
      (pkgs.fetchurl { url = "https://greasyfork.org/scripts/39311-hacker-news-highlighter/code/Hacker%20News%20Highlighter.user.js"; hash = "sha256-QZNhmtob3fxCYBnEGPpQ+jw84AEQjSspcTErlYWoujI="; })
      (pkgs.fetchurl { url = "https://greasyfork.org/scripts/23432-hacker-news-date-tooltips/code/Hacker%20News%20Date%20Tooltips.user.js"; hash = "sha256-S2c6egARy9hxejN6Ct/zshUT/sWr9w6+LMfrRnVsDw0="; })

      # Lobsters
      (pkgs.fetchurl { url = "https://greasyfork.org/scripts/392307-lobste-rs-open-in-new-tab/code/Lobsters%20Open%20in%20New%20Tab.user.js"; hash = "sha256-JuF4HlaN5udaDKAwCEJKdKKCggJloGAZkCptMXI0xys="; })
      (pkgs.fetchurl { url = "https://greasyfork.org/scripts/40906-lobsters-highlighter/code/Lobsters%20Highlighter.user.js"; hash = "sha256-CJyDG74QVsw5n4U1lztzymorZ96/P20ifQF+/PtJKMs="; })

      # Tumblr
      (pkgs.fetchurl { url = "https://greasyfork.org/scripts/31593-tumblr-images-to-hd-redirector/code/Tumblr%20Images%20to%20HD%20Redirector.user.js"; hash = "sha256-ArfFzIPFoLIoFVpxKVu5JWOhgmVE58L47ljbcI4yksM="; })

      # Bandcamp
      (pkgs.fetchurl { url = "https://greasyfork.org/scripts/423498-bandcamp-extended-album-history/code/Bandcamp%20extended%20album%20history.user.js"; hash = "sha256-4NNDhOo9yyessyjmEMk3Znz0aRZgA+wtQw+JaUuD+iE="; })
      (pkgs.fetchurl { url = "https://greasyfork.org/scripts/38012-bandcamp-volume-bar/code/Bandcamp%20Volume%20Bar.user.js"; hash = "sha256-bCMCQje8YBgjLXPzAgFvFo/MTzsE4JkdkZHjIW4C9hg="; })

      # Discord
      # { userscript = pkgs.fetchurl { url = "https://dht.chylex.com/build/track.user.js"; hash = "sha256-+6h9Pf9GPxZMif+vwpsGGL8wQoKWoOs3bs5IW4Wgbxw="; }; }

      # Twitter
      (pkgs.fetchurl { url = "https://greasyfork.org/scripts/404632-twitter-direct/code/Twitter%20Direct.user.js"; hash = "sha256-lUA+PPswJU9AyCrowRlG/h/+FhDT/1v927xowmbpYAw="; })
      (pkgs.fetchurl { url = "https://greasyfork.org/scripts/405103-twitter-linkify-trends/code/Twitter%20Linkify%20Trends.user.js"; hash = "sha256-YrXf0OgpZ1nvoBABj8X3YyEMWpPOseGhDrSi10ArMCA="; })
      (pkgs.fetchurl { url = "https://greasyfork.org/scripts/413963-twitter-zoom-cursor/code/Twitter%20Zoom%20Cursor.user.js"; hash = "sha256-tNWUn4LQZxn3ehfSzJ6KFs7H41+I7V8o9773Ua5uQJE="; })
      (pkgs.fetchurl { url = "https://openuserjs.org/install/Sapp/Twitter_Show_Timestamp.user.js"; hash = "sha256-q4YHRRPhP+3Qt0uqITpyK93VGM5I3Hs7wgZ2E9dAUsE="; })
      (pkgs.fetchurl { url = "https://greasyfork.org/scripts/400695-i-like-latest-tweets/code/I%20like%20latest%20tweets%20!.user.js"; hash = "sha256-AFrjUK1fymk5r5aMBHlrc9odmjxNr+Zb5lGhHKixgNo="; })
      (pkgs.fetchurl { url = "https://openuserjs.org/install/tomviner/Collapse_Twitter_Messages_Tab.user.js"; hash = "sha256-Bqi8koASSUpS1kHkBerP7ZI8wrVdWfZOQIwqzkM7riE="; })
      (pkgs.fetchurl { url = "https://raw.githubusercontent.com/yuhaofe/Video-Quality-Fixer-for-Twitter/master/vqfft.user.js"; hash = "sha256-JFBaqr7MDRwKbiGYm0b5YhcRhfkDWzg2Idf8N+U3pLs="; })

      # Reddit
      (pkgs.fetchurl { url = "https://greasyfork.org/scripts/39312-reddit-highlighter/code/Reddit%20Highlighter.user.js"; hash = "sha256-R53piHtc6P0EKmR51PUgHimdfN9UgnIY65El9XKxJiI="; })

      # Zoom
      (pkgs.fetchurl { url = "https://openuserjs.org/install/clemente/Zoom_redirector.user.js"; hash = "sha256-BWIOITDCDnbX2MCIcTK/JtqBaz4SU6nRu5f8WUbN8GE="; })

      # Mastodon
      # (pkgs.fetchurl { url = "https://openuserjs.org/install/leobm/Mastodon_DeepL_translate_button.user.js"; hash = "sha256-R0ycO8zLwTMpBYEWtvw6KkHa1vhUZmZwhB1GHOh//nE="; })

      # GitHub
      (pkgs.fetchurl { url = "https://greasyfork.org/scripts/411765-github-my-issues/code/GitHub%20My%20Issues.user.js"; hash = "sha256-hDHmrcU8by/L4H928WRQOz/RmXQvRUgqQNNzBtXU4Ek="; })
      (pkgs.fetchurl { url = "https://raw.githubusercontent.com/devxoul/github-monospace-editor/master/script/github-monospace-editor.user.js"; hash = "sha256-jH2WsbtSIxlyMyVLD0r7i+yKczwpAV/7CEh+vrc6yuY="; })

      # MusicBrainz
      (pkgs.fetchurl { name = "lib_mbimport.js"; url = "https://raw.githubusercontent.com/murdos/musicbrainz-userscripts/master/lib/mbimport.js"; hash = "sha256-YEWdDYSVTiqbz+k9CfaHjUqVCFSwndl9Ibfme3tHSrs="; })
      (pkgs.fetchurl { name = "lib_mbimportstyle.js"; url = "https://raw.githubusercontent.com/murdos/musicbrainz-userscripts/master/lib/mbimportstyle.js"; hash = "sha256-j8xS+EG6gCGQlan/iyDkWoPETwa0oTQwOwK9bt8bLko="; })
      (pkgs.fetchurl { name = "lib_mblinks.js"; url = "https://raw.githubusercontent.com/murdos/musicbrainz-userscripts/master/lib/mblinks.js"; hash = "sha256-189GEmgU/FopNQvEihU14EgYk9sMMvtfYtTXGE30csc="; })
      (pkgs.fetchurl { name = "lib_logger.js"; url = "https://raw.githubusercontent.com/murdos/musicbrainz-userscripts/master/lib/logger.js"; hash = "sha256-Ks+THhs22kFtKnxE8iGUa7qvxDwo/kq7HGRGIN+r/kk="; })

      (pkgs.fetchurl { url = "https://raw.githubusercontent.com/murdos/musicbrainz-userscripts/master/bandcamp_importer.user.js"; hash = "sha256-EwMkVG3w3UZvsxJXFtt87+bXUQi0SBWUEAXcVEmaSOw="; })
      (pkgs.fetchurl { url = "https://raw.githubusercontent.com/murdos/musicbrainz-userscripts/master/batch-add-recording-relationships.user.js"; hash = "sha256-3SjJ5IuieOBIhLeX9AU+hjmHmqfJbt5dKLJi0tQ4lcE="; })
      (pkgs.fetchurl { url = "https://raw.githubusercontent.com/murdos/musicbrainz-userscripts/master/beatport_classic_importer.user.js"; hash = "sha256-ZcsMJ6ltJK6MrSfQJ39VJKKTH8v4YoKrY4zfvlWP41Y="; })
      (pkgs.fetchurl { url = "https://raw.githubusercontent.com/murdos/musicbrainz-userscripts/master/beatport_importer.user.js"; hash = "sha256-U2nLscRu2YIBsYf5b/wHHx9kW7WpZpRVtRWvNnvioZQ="; })
      (pkgs.fetchurl { url = "https://raw.githubusercontent.com/murdos/musicbrainz-userscripts/master/discogs_importer.user.js"; hash = "sha256-/pMp4VoAea/CjbQodZWLvw0tosmurkZZ9OuPxN5Evl0="; })
      (pkgs.fetchurl { url = "https://raw.githubusercontent.com/murdos/musicbrainz-userscripts/master/edit-instrument-recordings-links.user.js"; hash = "sha256-64pjjDbg9LdzVUl0Jhwj/R3nvUI8nWlerVodTK7IH2w="; })
      (pkgs.fetchurl { url = "https://raw.githubusercontent.com/murdos/musicbrainz-userscripts/master/expand-collapse-release-groups.user.js"; hash = "sha256-Tevw4H/W7cqCQMcKadgZNreeRlixlPIGJqMLN39Jqn8="; })
      (pkgs.fetchurl { url = "https://raw.githubusercontent.com/murdos/musicbrainz-userscripts/master/fast-cancel-edits.user.js"; hash = "sha256-0XyMMLAjsONM284LKKSs2c40i1+s70CNuFVR1RdKpXI="; })
      (pkgs.fetchurl { url = "https://raw.githubusercontent.com/murdos/musicbrainz-userscripts/master/mb_discids_detector.user.js"; hash = "sha256-mb8KjYPsprhqO35IS0RHnJVVuLEqa7RFMl/pD6AUIjM="; })
      (pkgs.fetchurl { url = "https://raw.githubusercontent.com/murdos/musicbrainz-userscripts/master/mb_relationship_shortcuts.user.js"; hash = "sha256-wvrWaUE+Py7fcC1LAkWOt3cXFVhQDsG5nmnX2DZD10I="; })
      (pkgs.fetchurl { url = "https://raw.githubusercontent.com/murdos/musicbrainz-userscripts/master/set-recording-comments.user.js"; hash = "sha256-+m7whj8s010xITbSYGx3cYMNo4OFJoY/cBJUwUikEww="; })
      # { userscript = pkgs.fetchurl { url = "https://raw.githubusercontent.com/murdos/musicbrainz-userscripts/master/bandcamp_importer_helper.user.js"; hash = "sha256-njx5Itm/bRLbuJ43A8O9iJH/R/fgyp2FscduWDhvCOQ="; }; }

      (pkgs.fetchurl { url = "https://raw.githubusercontent.com/jesus2099/konami-command/master/mb_AUTO-FOCUS-KEYBOARD-SELECT.user.js"; hash = "sha256-sDxOxjHkPYXtAy/XXbeErS0wx9kRxGjMzbLBNRGnb0k="; })
      (pkgs.fetchurl { url = "https://raw.githubusercontent.com/jesus2099/konami-command/master/mb_ELEPHANT-EDITOR.user.js"; hash = "sha256-2ff471iQ/p6gXsi9iQsnyyOnmvo6S5H/TLaJ5wyRpug="; })
      (pkgs.fetchurl { url = "https://raw.githubusercontent.com/jesus2099/konami-command/master/mb_REDIRECT-WHEN-UNIQUE-RESULT.user.js"; hash = "sha256-Q7C4E+/M71/daAU9RHGhCEPdFUf5vMajZLAOa7c64dA="; })

      (pkgs.fetchurl { url = "https://raw.githubusercontent.com/loujine/musicbrainz-scripts/master/mb-edit-add_aliases.user.js"; hash = "sha256-pzouE0pxJo2x+cb3JoDVEcSj1USOzfqkSLjHb+1seyI="; })
    ];
  }

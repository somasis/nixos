{ config
, pkgs
, lib
, ...
}: {
  programs.qutebrowser.greasemonkey = map config.lib.somasis.drvOrPath [
    # YouTube
    (pkgs.fetchurl { hash = "sha256-YcjlG8GSSynwWvTLiWE+F6Wmdri5ZURSeqWXS1eaOIc="; url = "https://greasyfork.org/scripts/468740-restore-youtube-username-from-handle-to-custom/code/Restore%20YouTube%20Username%20from%20Handle%20to%20Custom.user.js"; })
    (pkgs.fetchurl { hash = "sha256-d0uEUoCFkh4Wfnr7Kaw/eSvG1Q6r/Fe7hMaTiOmbpOQ="; url = "https://greasyfork.org/scripts/431573-youtube-cpu-tamer-by-animationframe/code/YouTube%20CPU%20Tamer%20by%20AnimationFrame.user.js"; })
    # (pkgs.fetchurl { hash = "sha256-UpnrCuxWSkVeVTp2BpCl0FQd85GUVeL2gPkff2f/yQs="; url = "https://greasyfork.org/scripts/811-resize-yt-to-window-size/code/Resize%20YT%20To%20Window%20Size.user.js"; })
    # (pkgs.fetchurl { hash = "sha256-6FK4x/rZA1BxWOmYLjVU4rEFqXHgpwAy0rYedQzza2g="; url = "https://greasyfork.org/scripts/370755-youtube-peek-preview/code/Youtube%20Peek%20Preview.user.js"; })
    (pkgs.fetchurl { hash = "sha256-pKxroIOn19WvcvBKA5/+ZkkA2YxXkdTjN3l2SLLcC0A="; url = "https://gist.githubusercontent.com/codiac-killer/87e027a2c4d5d5510b4af2d25bca5b01/raw/764a0821aa248ec4126b16cdba7516c7190d287d/youtube-autoskip.user.js"; })
    (pkgs.fetchurl { hash = "sha256-LnorSydM+dA/5poDUdOEZ1uPoAOMQwpbLmadng3qCqI="; url = "https://greasyfork.org/scripts/23329-disable-youtube-60-fps-force-30-fps/code/Disable%20YouTube%2060%20FPS%20(Force%2030%20FPS).user.js"; })
    # (pkgs.fetchurl { hash = "sha256-DnGZSjC1YkrJZ1H9qQ50GjR9DK84kc4JPHfA2OxHY14="; url = "https://greasyfork.org/scripts/471062-youtube-shorts-blocker/code/YouTube%20Shorts%20Blocker.user.js"; })

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
  ];
}

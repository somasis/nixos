{ config
, lib
, pkgs
, ...
}:
with config.lib.somasis.feeds;
let
  inherit (pkgs) writeShellScript;
  inherit (lib) makeBinPath;

  redacted =
    { subfeed
    , title ? "Redacted: ${subfeed}"
    , tags ? [ ]
    }:
    let
      generate =
        writeShellScript "generate-redacted" ''
          PATH=${makeBinPath [ pkgs.curl config.programs.password-store.package ]}:"$PATH"

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
        '';
    in
    {
      url = urls.exec "${generate} https://redacted.ch/feeds.php?feed=feed_${subfeed}";
      inherit title;
      tags = [ "redacted" ] ++ tags;
    }
  ;
in
{
  lib.somasis.feeds.feeds.redacted = redacted;

  programs.newsboat.urls = [
    (redacted {
      subfeed = "news";
      tags = [ "music" "redacted" ];
    })
    (redacted {
      subfeed = "blog";
      tags = [ "music" "redacted" ];
    })
  ];
}

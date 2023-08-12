{ config
, pkgs
, lib
, inputs
, ...
}:
let
  uriList = map (x: "file://${x}");

  adblockCustom = pkgs.writeText "custom.txt" ''
    ! Disable smooth scroll hijacking scripts
    /jquery.nicescroll*.js
    /jquery.smoothscroll*.js
    /jquery.smooth-scroll*.js
    /jquery-smoothscroll*.js
    /jquery-smooth-scroll*.js
    /nicescroll*.js
    /smoothscroll*.js
    /smooth-scroll*.js
    /mousewheel-smooth-scroll
    /surbma-smooth-scroll
    /dexp-smoothscroll.js
  '';
in
{
  cache.files = [
    "share/qutebrowser/adblock-cache.dat"
    "share/qutebrowser/blocked-hosts"
  ];

  programs.qutebrowser = {
    settings = {
      # Help with jhide's memory usage.
      # qt.chromium.process_model = "process-per-site";

      content.blocking = {
        enabled = true;
        method = "adblock";
        adblock.lists = with inputs; uriList [
          adblockCustom

          adblockEasyList
          adblockEasyListCookies
          adblockEasyListSpanish
          adblockEasyListRussian
          adblockAntiAdblockFilters
          adblockFanboySocial
          uAssetsPrivacy
          uAssetsResourceAbuse
        ];
      };
    };

    greasemonkey = map
      config.lib.somasis.greasemonkey.jhide
      config.programs.qutebrowser.settings.content.blocking.adblock.lists
    ;
  };
}

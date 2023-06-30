{ pkgs, config, inputs, ... }:
let
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

  programs.qutebrowser.settings.content.blocking = {
    enabled = true;
    method = "adblock";
    adblock.lists = uriList [
      adblockCustom
      inputs.adblockEasyList
      inputs.adblockEasyListCookies
      inputs.adblockEasyListSpanish
      inputs.adblockEasyListRussian
      inputs.adblockAntiAdblockFilters
      inputs.adblockFanboySocial
      inputs.uAssetsPrivacy
      inputs.uAssetsResourceAbuse
    ];
  };
}

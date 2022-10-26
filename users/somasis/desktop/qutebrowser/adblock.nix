{ pkgs, config, ... }: {
  home.persistence."/cache${config.home.homeDirectory}".files = [
    "share/qutebrowser/adblock-cache.dat"
    "share/qutebrowser/blocked-hosts"
  ];

  programs.qutebrowser.settings.content.blocking =
    let
      custom = pkgs.writeText "adblock" ''
        ! Disable all smooth scroll hijacking scripts
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
      enabled = true;
      method = "adblock";
      # adblock.lists = [
      #   "https://easylist.to/easylist/easylist.txt"
      #   "https://easylist-downloads.adblockplus.org/easylistspanish.txt"
      #   "https://secure.fanboy.co.nz/fanboy-cookiemonster.txt"
      #   "https://easylist.to/easylist/fanboy-social.txt"
      #   "https://easylist-downloads.adblockplus.org/antiadblockfilters.txt"
      #   "https://raw.githubusercontent.com/uBlockOrigin/uAssets/master/filters/unbreak.txt"
      #   "https://easylist.to/easylist/easyprivacy.txt"
      #   "https://raw.githubusercontent.com/uBlockOrigin/uAssets/master/filters/privacy.txt"
      #   "https://raw.githubusercontent.com/uBlockOrigin/uAssets/master/filters/resource-abuse.txt"
      #   "file://${custom}"
      # ];
      adblock.lists =
        [ "file://${adblockCustom}" ]
        ++ builtins.map (x: "file://${x}") [
          inputs.adblockEasyList
          inputs.adblockEasyListSpanish
          inputs.adblockFanboyCookies
          inputs.adblockFanboySocial
          inputs.adblockAntiAdblock
          inputs.adblockEasyPrivacy
          inputs.uBlockUnbreak
          inputs.uBlockPrivacy
          inputs.uBlockResourceAbuse
        ];

      hosts.lists = builtins.map (x: "file://${x}") [
        "${inputs.adblockHosts}/hosts"
      ];
    };
}

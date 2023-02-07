{ pkgs, config, inputs, ... }: {
  home.persistence."/cache${config.home.homeDirectory}".files = [
    "share/qutebrowser/adblock-cache.dat"
    "share/qutebrowser/blocked-hosts"
  ];

  programs.qutebrowser.settings.content.blocking =
    let
      custom = (pkgs.writeText "adblock" ''
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
      '');
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
        builtins.map (x: "file://${x}") [
          custom
          (pkgs.runCommandLocal "adblockEasyList" { } ''
            exec > "$out"
            cat \
                "${inputs.adblockEasyList}"/easylist/*.txt \
                "${inputs.adblockEasyList}"/easylist_adult/*.txt
          '')
          (pkgs.runCommandLocal "adblockEasyPrivacy" { } ''
            exec > "$out"
            cat "${inputs.adblockEasyList}"/easyprivacy/*.txt
          '')
          (pkgs.runCommandLocal "adblockEasyListSpanish" { } ''
            exec > "$out"
            cat \
                "${inputs.adblockEasyListSpanish}"/easylistspanish/*.txt \
                "${inputs.adblockEasyListSpanish}"/easylistspanish_adult/*.txt
          '')
          (pkgs.runCommandLocal "adblockFanboyCookies" { } ''
            exec > "$out"
            cat "${inputs.adblockEasyList}"/easylist_cookie/*.txt
          '')
          (pkgs.runCommandLocal "adblockFanboyCookies" { } ''
            exec > "$out"
            cat "${inputs.adblockEasyList}"/fanboy-addon/fanboy_social*.txt
          '')
          (pkgs.concatTextFile {
            name = "adblockAntiAdblock";
            files = [
              "${inputs.adblockAntiAdblockFilters}/antiadblockfilters/antiadblock_english.txt"
              "${inputs.adblockAntiAdblockFilters}/antiadblockfilters/antiadblock_spanish.txt"
            ];
          })
          "${inputs.uBlock}/filters/privacy.txt"
          "${inputs.uBlock}/filters/resource-abuse.txt"
        ];

      hosts.lists = builtins.map (x: "file://${x}") [
        "${inputs.adblockHosts}/hosts"
      ];
    };
}

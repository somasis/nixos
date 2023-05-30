{ pkgs, config, inputs, ... }:
let
  uriList = builtins.map (x: "file://${builtins.toString x}");
in
{
  cache.files = [
    "share/qutebrowser/adblock-cache.dat"
    "share/qutebrowser/blocked-hosts"
  ];

  programs.qutebrowser.settings.content.blocking =
    let
      custom = pkgs.writeText "adblock" ''
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
      enabled = true;
      method = "adblock";
      adblock.lists =
        let
          listsFrom = src: subdirectory: pkgs.runCommandLocal "adblock"
            {
              inherit src subdirectory;
            } ''
            exec > "$out"
            cat $src/$subdirectory/*.txt
          '';
        in
        uriList [
          custom
          (listsFrom inputs.adblockEasyList "easylist")
          (listsFrom inputs.adblockEasyList "easylist_adult")
          (listsFrom inputs.adblockEasyList "easyprivacy")
          (listsFrom inputs.adblockEasyListSpanish "easylistspanish")
          (listsFrom inputs.adblockEasyListSpanish "easylistspanish_adult")
          (listsFrom inputs.adblockEasyList "easylist_cookie")
          (listsFrom inputs.adblockAntiAdblockFilters "antiadblockfilters")
          (listsFrom inputs.adblockAntiAdblockFilters "antiadblockfilters")
          "${inputs.adblockEasyList}/fanboy-addon/fanboy_social.txt"
          "${inputs.uAssets}/filters/privacy.txt"
          "${inputs.uAssets}/filters/resource-abuse.txt"
        ];

      hosts.lists = uriList [ "${inputs.adblockHosts}/hosts" ];
    };
}

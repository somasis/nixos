{ config
, pkgs
, lib
, inputs
, ...
}:
let
  uriList = map (x: "file://${x}");

  adblockCustom = pkgs.writeText "custom.txt" ''
    [Adblock Plus 2.0]
    ! Title: Custom ad blocking rules
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
      qt.chromium.process_model = "process-per-site";

      content.blocking = {
        enabled = true;
        method = "adblock";
        adblock.lists = uriList
          # (map
          #   (list:
          #     pkgs.runCommandLocal (builtins.baseNameOf (list.name or "${list}")) { inherit list; } ''
          #       ${pkgs.gnugrep}/bin/grep -v \
          #           -e "^! Last modified: " \
          #           -e "^! Expires: " \
          #           -e "^! Checksum: " \
          #           -e "^! Updated: " \
          #           ${lib.escapeShellArg list} \
          #           > "$out"
          #     ''
          #   )
          (with inputs; [
            adblockCustom

            adblockEasyList
            adblockEasyListSpanish
            adblockEasyListRussian

            adblockEasyPrivacy

            adblockEasyListCookies

            adblockAntiAdblockFilters

            # adblockFanboySocial
            # uAssetsPrivacy
            # uAssetsResourceAbuse
          ])
          # )
        ;
      };
    };

    greasemonkey = [
      (config.lib.somasis.greasemonkey.jhide
        (map
          (lib.replaceStrings [ "file://" ] [ "" ])
          config.programs.qutebrowser.settings.content.blocking.adblock.lists
        )
      )
    ];
  };
}

{ pkgs, config, ... }: {
  home.packages = [
    (pkgs.symlinkJoin {
      name = "urbanterror-final";

      paths = [
        (pkgs.writeShellScriptBin "urbanterror" ''
          ${pkgs.urbanterror}/bin/urbanterror "$@" 2>&1 \
              | TZ=UTC ${pkgs.moreutils}/bin/ts "%Y-%m-%dT%H:%M:%SZ" \
              | ${pkgs.coreutils}/bin/tee ~/logs/urt/$(date +%Y-%m-%dT%H:%M:%SZ).log >&2
        '')
        pkgs.urbanterror
      ];
    })
  ];
  home.persistence."/persist${config.home.homeDirectory}".directories = [ ".q3a" ];
  # home.file.".q3a/q3ut4/download" = {
  #   # <http://www.dswp.de/old/wiki/doku.php/tutorials:urban_terror:all-funstuff-ever>
  #   "zzzallfunstuffever.pk3".source = pkgs.fetchurl {
  #     url = "http://maps.dswp.de/q3ut4/zzzallfunstuffever.pk3";
  #     hash = "sha256-wdCJ6IHseTB3XvdabiguZ07IRWaAjP2+v86IS3cnIao=";
  #   };

  #   "ut4_happyfunstuffroom.pk3".source = pkgs.fetchurl {
  #     url = "http://www.mhermann.net/q3ut4/ut4_happyfunstuffroom.pk3";
  #     hash = "sha256-khtHWjqQKLLttajWfYIcfz9Fu5Rx3BjxrS91Ru4B8Lc=";
  #   };
  # };
}

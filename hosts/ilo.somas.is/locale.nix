{ pkgs, config, lib, ... }:
let
  locale = "en_US.UTF-8";
  localeType = builtins.toString (builtins.tail (lib.splitString "." "${locale}"));
in
{
  # Boone, NC, USA
  time.timeZone = "America/New_York";
  location = {
    latitude = 36.21641;
    longitude = -81.67464;
  };

  # Automatically update location and timezone when traveling.
  # services.localtimed.enable = true;

  services.geoclue2 = {
    enable = true;
    # enableDemoAgent = true;
    submitData = true;

    # Used by users/somasis/desktop/stw/wttr.nix.
    appConfig."geoclue-where-am-i" = {
      isAllowed = true;
      isSystem = false;
      users = [ (builtins.toString config.users.users.somasis.uid) ];
    };
  };
  location.provider = "geoclue2";

  cache.directories = [ "/var/lib/geoclue" ];

  # TODO: o kepeken toki pona
  #       ilo glibc nanpa 2.36 li jo e sona pi toki pona.
  #       nanpa 2.36 li lon ala poki ilo nixpkgs.
  #       <https://github.com/NixOS/nixpkgs/pull/188492>
  #
  # i18n.extraLocaleSettings.LANGUAGE = "tok:en_US:en";

  i18n = rec {
    defaultLocale = locale;
    supportedLocales = [ "${locale}/${localeType}" ];

    extraLocaleSettings.LC_COLLATE = "C";
    # extraLocaleSettings.LC_NUMERIC = "C.UTF-8";
    # extraLocaleSettings.LC_TIME = "en_DK.UTF-8/UTF-8";

    # TODO: It would be nice to have ISO dates and such as the default
    #       formats, but people recommend using some European locales
    #       for that, which feels like a poor solution.
    #       There's locale-en_XX, but I'm not sure how to put it into glibcLocales.
    #       <https://xyne.dev/projects/locale-en_xx/>
    # glibcLocales = pkgs.buildPackages.glibcLocales.overrideAttrs (oldAttrs: {
    #   allLocales = lib.any (x: x == "all") config.i18n.supportedLocales;
    #   locales = config.i18n.supportedLocales;
    #   # TODO: I'd really prefer to not patch it like this.
    #   patches = [ ./locale-en_XX.patch ];
    # });
    #
    # defaultLocale = "en_XX@POSIX";
    # extraLocaleSettings.LC_CTYPE = "en_US.UTF-8";
    # supportedLocales = [ "en_US/UTF-8" "en_XX/UTF-8@POSIX" ];
    #
    # TODO: Maybe do it like this?
    # glibcLocales = pkgs.glibcLocales.overrideAttrs {
    #   nativeBuildInputs = [
    #     (pkgs.stdenvNoCC.mkDerivation rec {
    #       pname = "locale-en_xx";
    #       version = "2017";

    #       src = pkgs.fetchzip {
    #         url = "https://xyne.dev/projects/${pname}/src/${pname}-${version}.tar.xz";
    #         hash = "sha256-EgvEZ5RVNMlDyzIPIpfr8hBD6lGbljtXhE4IjzJDq9I=";
    #       };

    #       nativeBuildInputs = [
    #         pkgs.glibcLocales
    #       ];

    #       installPhase = ''
    #         install -m0644 -D en_XX@POSIX $out/bin/execshell
    #       '';

    #       meta = with pkgs.lib; {
    #         description = "mixed international English locale using ISO and POSIX formats";
    #         license = licenses.gpl2;
    #         maintainers = maintainers.somasis;
    #         platforms = platforms.all;
    #       };
    #     })
    #   ];
    # };

    # TODO: sitelen pona input method
    # inputMethod = {
    #   enabled = "ibus";
    #   ibus = {
    #     engines =
    #       let
    #         sitelen-pona = pkgs.callPackage ../../pkgs/ibus-table-sitelen-pona { };
    #       in
    #       [
    #         pkgs.ibus-engines.table
    #         pkgs.ibus-engines.uniemoji
    #         sitelen-pona
    #       ];
    #   };
    # };
  };
}

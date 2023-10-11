{ pkgs, config, lib, ... }:
let
  locale = "en_US.UTF-8";
  localeType = builtins.toString (builtins.tail (lib.splitString "." "${locale}"));
in
{
  # Boone, NC, USA
  location = {
    latitude = 36.21641;
    longitude = -81.67464;
  };

  # Automatically update location and timezone when traveling,
  services.localtimed.enable = true;
  # with a fallback timezone.
  # time.timeZone can't be set when using automatic-timezoned; but that's bullshit.
  # See <https://github.com/NixOS/nixpkgs/issues/68489>
  # and <https://github.com/NixOS/nixpkgs/blob/master/pkgs/os-specific/linux/systemd/0006-hostnamed-localed-timedated-disable-methods-that-cha.patch#L79-L82>
  #
  # time.timeZone = "America/New_York";
  systemd.services.set-default-timezone = {
    description = "Set the default timezone at boot";
    wantedBy = [ "time-set.target" "basic.target" ];
    requires = [ "systemd-timesyncd.service" ];
    before = [ "localtimed.service" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${config.systemd.package}/bin/timedatectl set-timezone America/New_York";
    };
  };

  networking.networkmanager.dispatcherScripts = [{
    source = pkgs.writeShellScript "nm-localtimed" ''
      if [ "$2" = "up" ]; then systemctl start localtimed.service; fi
    '';
  }];

  services.geoclue2 = {
    enable = true;
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

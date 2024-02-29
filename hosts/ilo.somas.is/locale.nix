{ pkgs
, config
, lib
, ...
}:
let
  locale = "en_US.UTF-8";
  localeType = builtins.toString (builtins.tail (lib.splitString "." "${locale}"));

  normalUsers = lib.mapAttrsToList (n: v: toString v.uid) (lib.filterAttrs (n: v: v.isNormalUser) config.users.users);
in
{
  # Boone, NC, USA
  location = {
    latitude = 36.21641;
    longitude = -81.67464;
  };

  # Automatically update location and timezone when traveling,
  # with a fallback timezone.
  # services.automatic-timezoned.enable = true;
  services.localtimed.enable = true;
  networking.networkmanager.dispatcherScripts = [
    {
      source = pkgs.writeShellScript "nm-localtimed" ''
        if [ "$2" = "connectivity-change" ]; then systemctl start localtimed.service; fi
      '';
    }

    # {
    #   source = pkgs.writeShellScript "nm-chrony" ''
    #     PATH=${lib.makeBinPath [ config.services.chrony.package ]}:"$PATH"

    #     case "''${NM_DISPATCHER_ACTION,,}" in
    #         connectivity-change)
    #             case "''${CONNECTIVITY_STATE,,}" in
    #                 limited|full) chronyc online ;;
    #                 *) chronyc offline ;;
    #             esac
    #             ;;
    #         up|vpn-up) chronyc online ;;
    #         down|vpn-down) chronyc offline ;;
    #     esac
    #   '';
    # }
  ];

  # time.timeZone can't be set when using automatic-timezoned; but that's bullshit.
  #
  # See <https://github.com/NixOS/nixpkgs/issues/68489>
  # and <https://github.com/NixOS/nixpkgs/blob/master/pkgs/os-specific/linux/systemd/0006-hostnamed-localed-timedated-disable-methods-that-cha.patch#L79-L82>

  # time.timeZone = "America/New_York";

  boot.postBootCommands = ''
    ln -fs /etc/zoneinfo/America/New_York /etc/localtime
  '';

  # systemd.services.set-default-timezone = {
  #   description = "Set the default timezone at boot";
  #   wantedBy = [ "time-set.target" "basic.target" ];
  #   requires = [ "systemd-timesyncd.service" ];
  #   before = [ "localtimed.service" ];
  #   serviceConfig = {
  #     Type = "oneshot";
  #     ExecStart = "${config.systemd.package}/bin/timedatectl set-timezone America/New_York";
  #   };
  # };

  services.geoclue2 = {
    enable = true;
    submitData = true;

    appConfig = {
      where-am-i = {
        isAllowed = true;
        isSystem = false;
      };

      "org.qutebrowser.qutebrowser" = {
        isAllowed = true;
        isSystem = false;
      };
    };
  };

  systemd.user.services.geoclue-agent = {
    # Remove "network-online.target" dependencies, since they don't really work...
    # wants = lib.lists.remove "network-online.target" config.systemd.user.services.geoclue-agent.wants;
    # after = lib.lists.remove "network-online.target" config.systemd.user.services.geoclue-agent.after;
    wants = lib.mkForce [ ];
    after = lib.mkForce [ ];

    # then add them back through a hack since we can't really
    # declare a user service's dependency on a system service.
    # <https://github.com/systemd/systemd/issues/3312>
    preStart = ''
      ${pkgs.systemd-wait}/bin/systemd-wait -q network-online.target active
    '';
  };

  location.provider = "geoclue2";

  cache.directories = [
    { directory = "/var/lib/geoclue"; user = "geoclue"; group = "geoclue"; }
    { directory = "/var/lib/systemd/timesync"; user = "systemd-timesync"; group = "systemd-timesync"; }
  ];

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

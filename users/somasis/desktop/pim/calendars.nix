{ config
, osConfig
, lib
, pkgs
, ...
}:
let
  fastmail = type: userName: {
    inherit type;
    url = "https://${type}.messagingengine.com";
    inherit userName;
    passwordCommand = [
      (toString (pkgs.writeShellScript "password-command" ''
        ${config.programs.password-store.package}/bin/pass \
            ${lib.escapeShellArg osConfig.networking.fqdnOrHostName}/vdirsyncer/${lib.escapeShellArg userName}
      ''))
    ];
  };

  vdirsyncerConfig =
    lib.recursiveUpdate {
      enable = true;
      metadata = [ "displayname" "color" "description" "order" ];
      conflictResolution = "remote wins";
    }
  ;
in
rec {
  # NOTE nixpkgs-unstable's khal runs into a ridiculous amount of build failures.
  nixpkgs.overlays = [ (final: prev: { inherit (pkgs.stable) khal; }) ];

  accounts.calendar = {
    basePath = "calendars";

    accounts = {
      personal = { name, ... }: rec {
        primary = true;
        primaryCollection = "Calendar";

        local = {
          type = "filesystem";
          fileExt = ".ics";
        };

        remote = fastmail "caldav" "kylie@somas.is";

        vdirsyncer = vdirsyncerConfig {
          collections = [
            "66b2cb1d-142a-45c4-a69d-29088d7bb857"
            "62cb408f-6476-40c9-bd04-bb8376cb6098"
            "069e7367-d705-4992-88cc-e962388b2289"
            "b5460bba-446f-4c9a-9b75-7da771e7239c"
            "1d0980c8-f93f-47c1-ab2d-257dd15bffaf"
            "406cda7f-c807-4b33-ad8b-f7b108e1a31c"
            "bd1b9987-2b26-48d1-b9f4-5483204f74d9"
            "6910c6d1-2786-4151-83c6-c7bee7dc4c45"
          ];
        };

        khal = {
          enable = true;
          priority = 1;
          type = "discover";
          glob = "*";
        };
      };

      personal_ro = { name, ... }: rec {
        local = {
          type = "filesystem";
          fileExt = ".ics";
        };

        remote = fastmail "caldav" "kylie@somas.is";

        vdirsyncer = vdirsyncerConfig {
          collections = [
            "f7f289f1-3f30-45b9-832f-bee5c85fb79c"
            "0df570cd-038d-4a55-b7b4-4d522deb4321"
            "fe8edc23-dbea-42dd-b4ca-ee5e5f0e2241"
            "19bd5457-852d-47e0-87ba-1dcf485c018b"
            "a24bf95b-ef6e-428e-a5d9-26be33dffce5"
          ];
        };

        khal = {
          enable = true;
          priority = 0;
          type = "discover";
          glob = "*";
          readOnly = true;
        };
      };

      # university = { name, ... }: rec {
      #   primary = false;

      #   local = {
      #     type = "filesystem";
      #     fileExt = ".ics";
      #   };

      #   remote = fastmail "caldav" "kylie@somas.is";

      #   vdirsyncer = vdirsyncerConfig {
      #     collections = [];
      #   };

      #   khal = {
      #     enable = true;
      #     type = "discover";
      #     glob = "*";
      #     priority = 2;
      #     readOnly = true;
      #   };
      # };

      university_ro = { name, ... }: rec {
        primary = false;

        local = {
          type = "filesystem";
          fileExt = ".ics";
        };

        remote = fastmail "caldav" "kylie@somas.is";

        vdirsyncer = vdirsyncerConfig {
          collections = [
            "b57309e9-03ac-4f84-adba-1dc2d35c4c2a"
            "f900756d-1e77-4f48-ad97-3d719c9c775a"
            "994b7fe6-75fc-4676-8a39-5c49b7941029"
            "7060b481-f90a-4bfe-8df7-b2b9a6079a5f"
          ];
        };

        khal = {
          enable = true;
          type = "discover";
          glob = "*";
          priority = 3;
          readOnly = true;
        };
      };

      others_ro = { name, ... }: rec {
        primary = false;

        local = {
          type = "filesystem";
          fileExt = ".ics";
        };

        remote = fastmail "caldav" "kylie@somas.is";

        vdirsyncer = vdirsyncerConfig {
          collections = [
            "5f6873b5-3bcd-4704-b46c-bfe59eca665d"
            "e4d7681e-c502-4999-ba48-85d17090d5c3"
            "46897711-6880-4dc7-bc48-be23a8c86df5"
            "5bfbb874-f100-4cd5-8d2f-d2bf13ddf1bf"
            "156886b0-51f6-4167-b43e-78beccde11aa"
            "66c5ec19-fa45-4b8b-9886-48f645c0c15d"
            "1ecc51cd-ce74-4929-9221-f0f3b30f9ffb"
            "792a8695-6ce1-4c55-80fb-f560369a02d4"
          ];
        };

        khal = {
          enable = true;
          type = "discover";
          glob = "*";
          readOnly = true;
        };
      };
    };
  };

  home.packages = [
    # pkgs.playtime

    (pkgs.writeShellScriptBin "ikhal-personal" ''
      exec khal-personal interactive "$@"
    '')

    # ${lib.toShellVar "university"         config.accounts.calendar.accounts.university.vdirsyncer.collections}
    # ${lib.toShellVar "path_university"    config.accounts.calendar.basePath}/university
    (pkgs.writeShellScriptBin "khal-personal" ''
      ${lib.toShellVar "personal"           config.accounts.calendar.accounts.personal.vdirsyncer.collections}
      ${lib.toShellVar "personal_ro"        config.accounts.calendar.accounts.personal_ro.vdirsyncer.collections}
      ${lib.toShellVar "university_ro"      config.accounts.calendar.accounts.university_ro.vdirsyncer.collections}
      ${lib.toShellVar "path_personal"      config.accounts.calendar.basePath}/personal
      ${lib.toShellVar "path_personal_ro"   config.accounts.calendar.basePath}/personal_ro
      ${lib.toShellVar "path_university_ro" config.accounts.calendar.basePath}/university_ro

      khal_args=()

      for a in "''${personal[@]}"; do khal_args+=( "-a" "$(<"$path_personal"/"$a"/displayname)" ); done
      for a in "''${personal_ro[@]}"; do khal_args+=( "-a" "$(<"$path_personal_ro"/"$a"/displayname)" ); done
      # for a in "''${university[@]}"; do khal_args+=( "-a" "$(<"$path_university"/"$a"/displayname)" ); done
      for a in "''${university_ro[@]}"; do khal_args+=( "-a" "$(<"$path_university_ro"/"$a"/displayname)" ); done

      khal_command=
      for a; do
          case "$a" in
              -*) continue ;;
              *) khal_command="$a"; shift; break ;;
          esac
      done

      if [[ -n "''${khal_command:-}" ]]; then
          set -- "$khal_command" "''${khal_args[@]}" "$@"
          exec ${pkgs.khal}/bin/khal "$@"
      else
          set -- "$@" "''${khal_args[@]}"
          exec ${pkgs.khal}/bin/khal "$@"
      fi
    '')
  ];

  programs.khal = {
    enable = true;

    locale = {
      timeformat = "%I:%M %p";
      dateformat = "%Y-%m-%d";
      longdateformat = "%Y-%m-%d";
      datetimeformat = "%Y-%m-%d %I:%M %p";
      longdatetimeformat = "%Y-%m-%d %I:%M %p";

      firstweekday = 0;

      weeknumbers = "left";

      unicode_symbols = false;
    };

    settings.view = {
      blank_line_before_day = true;
      event_format = "{calendar-color}{cancelled}{start-end-time-style} {title}{repeat-symbol}{alarm-symbol}{reset}";
      agenda_event_format = "{calendar-color}{cancelled}{start-end-time-style} {title}{repeat-symbol}{alarm-symbol}{reset}";

      frame = "top";
    };
  };

  systemd.user.services.vdirsyncer.Service.ExecStartPost = [
    (pkgs.writeShellScript "khal-update-cache" ''
      ${pkgs.khal}/bin/khal list >/dev/null
    '')
  ];

  # use accounts.* without config so that we get it before the path is made absolute
  persist.directories = lib.mkMerge [
    (map
      (account: { method = "symlink"; directory = "${accounts.calendar.basePath}/${account}"; })
      (builtins.attrNames accounts.calendar.accounts)
    )
  ];

  cache.directories = [{ method = "symlink"; directory = config.lib.somasis.xdgDataDir "khal"; }];
}

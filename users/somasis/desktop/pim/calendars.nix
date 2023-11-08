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
  # nixpkgs-unstable's khal runs into a ridiculous amount of build failures.
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
            "069e7367-d705-4992-88cc-e962388b2289"
            "1d0980c8-f93f-47c1-ab2d-257dd15bffaf"
            "62cb408f-6476-40c9-bd04-bb8376cb6098"
            "66b2cb1d-142a-45c4-a69d-29088d7bb857"
            "6910c6d1-2786-4151-83c6-c7bee7dc4c45"
            "b5460bba-446f-4c9a-9b75-7da771e7239c"
            "bd1b9987-2b26-48d1-b9f4-5483204f74d9"
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
            "a24bf95b-ef6e-428e-a5d9-26be33dffce5"
            "46897711-6880-4dc7-bc48-be23a8c86df5"
            "0df570cd-038d-4a55-b7b4-4d522deb4321"
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

      university = { name, ... }: rec {
        primary = false;

        local = {
          type = "filesystem";
          fileExt = ".ics";
        };

        remote = fastmail "caldav" "kylie@somas.is";

        vdirsyncer = vdirsyncerConfig {
          collections = [
            "acfc59e6-8aa5-4b40-9db2-54459b7efefc"
          ];
        };

        khal = {
          enable = true;
          type = "discover";
          glob = "*";
          priority = 2;
          readOnly = true;
        };
      };

      university_ro = { name, ... }: rec {
        primary = false;

        local = {
          type = "filesystem";
          fileExt = ".ics";
        };

        remote = fastmail "caldav" "kylie@somas.is";

        vdirsyncer = vdirsyncerConfig {
          collections = [
            "781d751f-34d0-42f6-86d6-6b7263def307"
            "a4ca6dd7-96b3-46af-9323-f9251d855db7"
            "abdc2066-54fb-44e9-9f3d-5597e8e3f047"
            "ba199a48-3069-4317-bc7c-98b2b60def26"
            "fe8edc23-dbea-42dd-b4ca-ee5e5f0e2241"
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
            "04cd6e3c-f738-45f1-b8f1-736cb5043640"
            "444c093a-d07c-40f2-b9e3-210fb0467041"
            "5bfbb874-f100-4cd5-8d2f-d2bf13ddf1bf"
            "66c5ec19-fa45-4b8b-9886-48f645c0c15d"
            "792a8695-6ce1-4c55-80fb-f560369a02d4"
            "c64932da-80e3-4e11-92f2-389a076595a1"
            "d6c28153-f18e-4ead-aecd-5984f78621fd"
            "e4d7681e-c502-4999-ba48-85d17090d5c3"
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

    (pkgs.writeShellScriptBin "khal-personal" ''
      ${lib.toShellVar "personal"           config.accounts.calendar.accounts.personal.vdirsyncer.collections}
      ${lib.toShellVar "personal_ro"        config.accounts.calendar.accounts.personal_ro.vdirsyncer.collections}
      ${lib.toShellVar "university"         config.accounts.calendar.accounts.university.vdirsyncer.collections}
      ${lib.toShellVar "university_ro"      config.accounts.calendar.accounts.university_ro.vdirsyncer.collections}
      ${lib.toShellVar "path_personal"      config.accounts.calendar.basePath}/personal
      ${lib.toShellVar "path_university"    config.accounts.calendar.basePath}/university
      ${lib.toShellVar "path_personal_ro"   config.accounts.calendar.basePath}/personal_ro
      ${lib.toShellVar "path_university_ro" config.accounts.calendar.basePath}/university_ro

      khal_args=()

      for a in "''${personal[@]}"; do khal_args+=( "-a" "$(<"$path_personal"/"$a"/displayname)" ); done
      for a in "''${personal_ro[@]}"; do khal_args+=( "-a" "$(<"$path_personal_ro"/"$a"/displayname)" ); done
      for a in "''${university[@]}"; do khal_args+=( "-a" "$(<"$path_university"/"$a"/displayname)" ); done
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

  cache.directories = [{ method = "symlink"; directory = "share/khal"; }];
}

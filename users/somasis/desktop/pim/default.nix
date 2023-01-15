{ nixosConfig, config, lib, pkgs, ... }:
let
  data = "${config.xdg.dataHome}/vdirsyncer";
  mkCollection = collections: "[" + (lib.concatStringsSep "," (map (x: ''"${x}"'') collections)) + "]";
in
{
  imports = [
    ./calendar.nix
    ./contacts.nix
  ];

  home.packages = [ pkgs.vdirsyncer ];

  xdg.configFile."vdirsyncer/config".text =
    let
      username = "kylie@somas.is";
      calendar_collections = mkCollection [
        # Calendars
        "66b2cb1d-142a-45c4-a69d-29088d7bb857" # Calendar
        "62cb408f-6476-40c9-bd04-bb8376cb6098" # Diet
        "069e7367-d705-4992-88cc-e962388b2289" # Ledger
        "b5460bba-446f-4c9a-9b75-7da771e7239c" # University

        # Google (kylie@somas.is)
        "1d0980c8-f93f-47c1-ab2d-257dd15bffaf" # Google Calendar: kylie@somas.is
        "bd1b9987-2b26-48d1-b9f4-5483204f74d9" # Violet & Kylie
        "6910c6d1-2786-4151-83c6-c7bee7dc4c45" # Jonesers

        # Google (mcclainkj@appstate.edu)
        "acfc59e6-8aa5-4b40-9db2-54459b7efefc" # Google Calendar: mcclainkj@appstate.edu
      ];
      calendar_readonly_collections = mkCollection [
        # Subscriptions
        "fe8edc23-dbea-42dd-b4ca-ee5e5f0e2241" # University: classes
        "e4d7681e-c502-4999-ba48-85d17090d5c3" # Cassie
        "5bfbb874-f100-4cd5-8d2f-d2bf13ddf1bf" # Cassie: university
        "66c5ec19-fa45-4b8b-9886-48f645c0c15d" # Violet: university
        "444c093a-d07c-40f2-b9e3-210fb0467041" # Zeyla
        "04cd6e3c-f738-45f1-b8f1-736cb5043640" # Zeyla: work
        "c64932da-80e3-4e11-92f2-389a076595a1" # Jes: university
        "a24bf95b-ef6e-428e-a5d9-26be33dffce5" # Holiday: North Carolina
        "a074e6e1-676c-414b-ac72-8709731ed134" # Holiday: South Australia
        "8d38d1e1-2d3b-4d61-b401-450634b548f5" # Holiday: Washington

        # Google (kylie@somas.is)
        "792a8695-6ce1-4c55-80fb-f560369a02d4" # Violet

        # Google (mcclainkj@appstate.edu)
        "8286567d-a494-469f-a8f3-4b98e4881f5f" # Appalachian State University: academic
        "ba199a48-3069-4317-bc7c-98b2b60def26" # Appalachian State University: registration
        "781d751f-34d0-42f6-86d6-6b7263def307" # Work
      ];
    in
    ''
      [general]
          status_path = "${config.xdg.cacheHome}/vdirsyncer/status"

      [storage calendar_local]
          type = "filesystem"
          path = "${data}/calendars"
          fileext = ".ics"

      [pair calendar]
          a = "calendar_remote"
          b = "calendar_local"
          conflict_resolution = "a wins"

          metadata = ["displayname", "color"]
          collections = ${calendar_collections}

      [pair calendar_readonly]
          a = "calendar_remote"
          b = "calendar_local_readonly"
          conflict_resolution = "a wins"

          partial_sync = "ignore"

          metadata = ["displayname", "color"]
          collections = ${calendar_readonly_collections}

      [storage calendar_local_readonly]
          type = "filesystem"
          path = "${data}/calendars_readonly"
          fileext = ".ics"
          read_only = "true"

      [storage calendar_remote]
          type = "caldav"
          url = "https://caldav.messagingengine.com/"
          username = "${username}"
          password.fetch = ["command", "pass", "${nixosConfig.networking.fqdn}/vdirsyncer/${username}"]

      [pair contacts]
          a = "contacts_remote"
          b = "contacts_local"
          conflict_resolution = "a wins"

          metadata = ["displayname"]
          collections = ["from a"]

      [storage contacts_local]
          type = "filesystem"
          path = "${data}/contacts"
          fileext = ".vcf"

      [storage contacts_remote]
          type = "carddav"
          url = "https://carddav.messagingengine.com/"
          username = "${username}"
          password.fetch = ["command", "pass", "${nixosConfig.networking.fqdn}/vdirsyncer/${username}"]
    '';

  systemd.user.services.vdirsyncer = {
    Unit.Description = pkgs.vdirsyncer.meta.description;

    Service = {
      Type = "oneshot";
      # ExecStartPre = "${pkgs.writeShellScript "vdirsyncer-discover" ''
      #   if ! [ -d "${data}/calendars" ] || ! [ -d "${data}/contacts" ]; then
      #     # Automatically create any new remote collections locally
      #     yes y | ${pkgs.vdirsyncer}/bin/vdirsyncer discover
      #     exit $?
      #   else
      #     exit 0
      #   fi
      #   ''
      # }";

      ExecStart = [
        "${pkgs.torsocks}/bin/torsocks ${pkgs.limitcpu}/bin/cpulimit -qf -l 50 -- ${pkgs.vdirsyncer}/bin/vdirsyncer metasync"
        "${pkgs.torsocks}/bin/torsocks ${pkgs.limitcpu}/bin/cpulimit -qf -l 50 -- ${pkgs.vdirsyncer}/bin/vdirsyncer sync"
      ];

      SyslogIdentifier = "vdirsyncer";

      Nice = 19;
      CPUSchedulingPolicy = "idle";
      IOSchedulingClass = "idle";
      IOSchedulingPriority = 7;
    };
  };

  systemd.user.timers.vdirsyncer = {
    Unit = {
      Description = "Synchronize calendars and contacts every thirty minutes, and fifteen minutes after startup";
      PartOf = [ "pim.target" ];
    };
    Install.WantedBy = [ "pim.target" ];

    Timer = {
      OnStartupSec = "900";
      OnCalendar = "*:0/30";
      RandomizedDelaySec = "5m";
    };
  };

  systemd.user.paths.vdirsyncer = {
    Unit.Description = "Synchronize calendars and contacts on local changes";
    Install.WantedBy = [ "pim.target" ];

    Path = {
      PathChanged = "${data}";
      Unit = "vdirsyncer.service";
    };
  };

  systemd.user.targets.pim = {
    Unit = {
      Description = "Calendar and contact related services";
      PartOf = [ "default.target" ];
    };

    Install.WantedBy = [ "default.target" ];
  };

  home.persistence."/persist${config.home.homeDirectory}".directories = [
    "share/vdirsyncer/calendars"
    "share/vdirsyncer/calendars_readonly"
    "share/vdirsyncer/contacts"
  ];

  home.persistence."/cache${config.home.homeDirectory}".directories = [ "var/cache/vdirsyncer" ];
}

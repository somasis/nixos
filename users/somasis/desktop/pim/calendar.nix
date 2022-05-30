{ pkgs, config, ... }: {
  home = {
    packages = [
      pkgs.khal
      # pkgs.remhind
    ];
    persistence."/cache${config.home.homeDirectory}".directories = [ "share/khal" ];
  };

  xdg.configFile."khal/config".text = ''
    [calendars]

        [[calendars_local]]
            type = discover
            path = ${config.xdg.dataHome}/vdirsyncer/calendars/*

        [[calendars_readonly_local]]
            type = discover
            path = ${config.xdg.dataHome}/vdirsyncer/calendars_readonly/*
            readonly = True

        [[Birthdays]]
            type = birthdays
            path = ${config.xdg.dataHome}/vdirsyncer/contacts/Default/

    [default]
        default_calendar = "Calendar"
        highlight_event_days = True

    [locale]
        timeformat = "%I:%M %p"
        dateformat = "%Y-%m-%d"
        longdateformat = "%Y-%m-%d"
        datetimeformat = "%Y-%m-%d %I:%M %p"
        longdatetimeformat = "%Y-%m-%d %I:%M %p"

        weeknumbers = "left"
  '';

  # xdg.configFile."remhind/config".source = (pkgs.formats.toml { }).generate "config" {
  #   calendars = {
  #     "Calendar" = {
  #       name = "Calendar";
  #       path = "${config.xdg.dataHome}/vdirsyncer/calendars/66b2cb1d-142a-45c4-a69d-29088d7bb857";
  #     };

  #     "Diet" = {
  #       name = "Diet";
  #       path = "${config.xdg.dataHome}/vdirsyncer/calendars/62cb408f-6476-40c9-bd04-bb8376cb6098";
  #     };

  #     "Ledger" = {
  #       name = "Ledger";
  #       path = "${config.xdg.dataHome}/vdirsyncer/calendars/069e7367-d705-4992-88cc-e962388b2289";
  #     };

  #     "University" = {
  #       name = "University";
  #       path = "${config.xdg.dataHome}/vdirsyncer/calendars/b5460bba-446f-4c9a-9b75-7da771e7239c";
  #     };

  #     "Google Calendar: kylie@somas.is" = {
  #       name = "Google Calendar: kylie@somas.is";
  #       path = "${config.xdg.dataHome}/vdirsyncer/calendars/1d0980c8-f93f-47c1-ab2d-257dd15bffaf";
  #     };

  #     "Violet & Kylie" = {
  #       name = "Violet & Kylie";
  #       path = "${config.xdg.dataHome}/vdirsyncer/calendars/bd1b9987-2b26-48d1-b9f4-5483204f74d9";
  #     };

  #     "Jonesers" = {
  #       name = "Jonesers";
  #       path = "${config.xdg.dataHome}/vdirsyncer/calendars/6910c6d1-2786-4151-83c6-c7bee7dc4c45";
  #     };

  #     "University: classes" = {
  #       name = "University: classes";
  #       path = "${config.xdg.dataHome}/vdirsyncer/calendars/fe8edc23-dbea-42dd-b4ca-ee5e5f0e2241";
  #     };

  #     "Google Calendar: mcclainkj@appstate.edu" = {
  #       name = "Google Calendar: mcclainkj@appstate.edu";
  #       path = "${config.xdg.dataHome}/vdirsyncer/calendars/acfc59e6-8aa5-4b40-9db2-54459b7efefc";
  #     };

  #     "Holiday: North Carolina" = {
  #       name = "Holiday: North Carolina";
  #       path = "${config.xdg.dataHome}/vdirsyncer/calendars/a24bf95b-ef6e-428e-a5d9-26be33dffce5";
  #     };
  #   };
  # };
}

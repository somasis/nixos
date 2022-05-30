{ pkgs, config, ... }: {
  home = {
    packages = [ pkgs.khard ];
    # persistence."/cache${config.home.homeDirectory}".directories = [ "share/khal" ];
  };

  #   xdg.configFile."khal/config".text = ''
  #     [calendars]

  #         [[calendars_local]]
  #             type = discover
  #             path = ${config.xdg.dataHome}/vdirsyncer/calendars/*

  #         [[calendars_readonly_local]]
  #             type = discover
  #             path = ${config.xdg.dataHome}/vdirsyncer/calendars_readonly/*
  #             readonly = True

  #         [[Birthdays]]
  #             type = birthdays
  #             path = ${config.xdg.dataHome}/vdirsyncer/contacts/Default/

  #     [default]
  #         default_calendar = "Calendar"
  #         highlight_event_days = True

  #     [locale]
  #         timeformat = "%I:%M %p"
  #         dateformat = "%Y-%m-%d"
  #         longdateformat = "%Y-%m-%d"
  #         datetimeformat = "%Y-%m-%d %I:%M %p"
  #         longdatetimeformat = "%Y-%m-%d %I:%M %p"

  #         weeknumbers = "left"
  #   '';
}

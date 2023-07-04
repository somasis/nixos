{ config
, lib
, ...
}: {
  programs.bash = {
    historyFile = lib.mkDefault "/dev/null";
    historyFileSize = lib.mkDefault 0;
    historyControl = [ "ignoredups" ]
      # kitty's shell integration will complain if "ignorespace" is in $HISTCONTROL.
      ++ lib.optional (!config.programs.kitty.enable) "ignorespace"
    ;

    sessionVariables.HISTTIMEFORMAT = "%Y-%m-%dT%H:%M:%S ";
  };
}

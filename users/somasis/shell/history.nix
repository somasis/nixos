{ lib, ... }: {
  programs.bash = {
    historyFile = lib.mkDefault "/dev/null";
    historyFileSize = lib.mkDefault 0;
    historyControl = [ "ignoredups" "ignorespace" ];

    sessionVariables.HISTTIMEFORMAT = "%Y-%m-%dT%H:%M:%S ";
  };
}

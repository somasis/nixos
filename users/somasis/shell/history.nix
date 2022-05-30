{
  programs.bash = {
    historyFile = "/dev/null";
    historyFileSize = 0;
    historyControl = [ "ignorespace" "ignoredups" ];
    shellOptions = [ "-histappend" ];
  };
}

{
  # Tweaks for cd(1) usage.

  programs.bash = {
    sessionVariables."CDPATH" = ".:$HOME:$HOME/study:$HOME/src:$HOME/mnt";
    shellAliases = {
      "back" = ''cd "$OLDPWD"'';
      ".." = "cd ..";
    };
    shellOptions = [ "cdspell" ];
  };
}

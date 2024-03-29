{
  # Tweaks for cd(1) usage.

  home = {
    sessionVariables."CDPATH" = ".:$HOME:$HOME/study:$HOME/src:$HOME/mnt";
    shellAliases = {
      "back" = ''cd "$OLDPWD"'';
      ".." = "cd ..";
    };
  };
  programs.bash.shellOptions = [
    "autocd" # `cd` into directories given as commands
    "cdspell" # correct directory misspellings
  ];
}

{
  # Aliases to make working with git(1) smoother
  programs.bash.shellAliases = {
    am = "git am";
    add = "git add -v";
    addall = "git addall";
    addp = "git addp";
    unadd = "git unadd";

    checkout = "git checkout";
    restore = "git restore";
    com = "git commit";
    amend = "git commit -v --amend";
    amendall = "addall;EDITOR=cat amend >/dev/null";

    clone = "git clone -vv";
    push = "git push -vv";
    pull = "git pull -vv";

    status = "git status --show-stash -sb";
    log = "git log --patch-with-stat --summary -M -C -C";
    commits = "git log --reverse --oneline @{upstream}..@";

    merge = "git merge";

    stash = "git stash";
    pop = "git stash pop";

    rebase = "git rebase";
    rbc = "git rbc";
    re = "git re";
    ri = "git ri";

    branch = "git branch -v";
    reset = "git reset";
    switch = "git switch";
    cherry = "git cherry-pick";
  };

  programs.bash.initExtra = ''
    _git_prompt() {
        [ -n "''${_git_prompt:=$(git rev-parse --abbrev-ref=loose HEAD 2>/dev/null)}" ] \
            && printf '%s ' "''${_git_prompt}"
        _git_prompt=
    }

    gitlukin() {
        set -- $(
            git log \
                --color=always \
                --no-merges \
                --oneline \
                --reverse "$@" \
            | sk \
                --ansi \
                --no-sort \
                -d ' ' \
                --preview='git log --color=always -1 --patch-with-stat {1}' \
                --preview-window=down:75% \
            | cut -d' ' -f1
        )
        log --no-merges "$@"
    }
  '';
}

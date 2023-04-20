{ config
, pkgs
, ...
}:
{
  imports = [
    ./gh.nix

    # TODO: Not included in home-manager 22.05
    # ./spr.nix

    ./signing.nix
  ];

  programs.git = {
    enable = true;
    package = pkgs.gitFull;

    userName = "Kylie McClain";
    userEmail = "kylie@somas.is";

    aliases = {
      addall = "add -Av";
      addp = "add -p";
      amend = "commit --amend";
      amendall = "!git addall; EDITOR=cat git amend";
      com = "commit";
      commits = "log --reverse --oneline @{upstream}...HEAD";
      patches = "format-patch -M -C -C --stdout origin..HEAD";
      rbc = "rebase --continue";
      re = "rebase";
      ri = "rebase -i";
      unadd = "reset HEAD --";
    };

    extraConfig = {
      sendemail = {
        annotate = true;
        smtpserver = "${pkgs.msmtp}/bin/msmtp";
      };

      init.defaultBranch = "main";
      interactive.singlekey = true;

      # Use the built-in version of `add -p` rather than the Perl script.
      add.interactive.useBuiltin = true;

      commit.verbose = true;

      pull.rebase = true;
      push = {
        default = "simple";
        rebase = true;
      };

      log.abbrevCommit = false;

      branch = {
        autoSetupRebase = "always";
        autoSetupMerge = "simple";
      };

      stash.showPatch = true;
      status.showStash = true;

      # Parallelize more things.
      checkout.workers = "-1";
      fetch.parallel = "0";
      submodule.fetchJobs = "0";

      # <https://github.com/NixOS/nixpkgs/issues/169193#issuecomment-1116090241>
      safe.directory = "*";

      url = {
        "ssh://git@github.com:".insteadOf = "gh:";
        "ssh://git@gitlab.com:".insteadOf = "gl:";
        "ssh://git@git.sr.ht:".insteadOf = "srht:";
      };
    };
  };

  home.shellAliases = {
    am = "git am";
    add = "git add -v";
    addall = "git addall";
    addp = "git addp";
    unadd = "git unadd";

    checkout = "git checkout";
    restore = "git restore";
    reset = "git reset";

    com = "git commit";
    amend = "git commit -v --amend";
    amendall = "addall;EDITOR=cat amend >/dev/null";

    clone = "git clone -vv";
    push = "git push -vv";
    pull = "git pull -vv";

    status = "git status --show-stash -sb";
    log = "git log --patch-with-stat --summary -M -C -C";
    commits = "git commits";

    merge = "git merge";

    stash = "git stash";
    pop = "git stash pop";

    rebase = "git rebase";
    rbc = "git rbc";
    re = "git re";
    ri = "git ri";

    branch = "git branch -v";
    switch = "git switch";
    cherry = "git cherry-pick";
    branchoff = "git branchoff";
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

  programs.kakoune.config.hooks = [
    # Show git diff on save
    {
      name = "BufCreate";
      option = ".*";
      commands = "evaluate-commands %sh{ git rev-parse >/dev/null 2>&1 && echo git show-diff }";
    }
    {
      name = "BufWritePost";
      option = ".*";
      commands = "evaluate-commands %sh{ git rev-parse >/dev/null 2>&1 && echo git show-diff }";
    }

    # Lightly enforce the 50/72 rule for git(1) commit summaries.
    {
      name = "WinSetOption";
      option = "filetype=git-commit";
      commands = ''
        # Commit title; everything over 50 is yellow.
        add-highlighter window/ regex \A\n*[^#\n]{50}([^\n]+) 1:black,yellow+f

        # Line following the title should be empty.
        add-highlighter window/ regex \A[^\n]*\n([^#\n]+) 1:white,red+b
      '';
    }

    # Wrap git commits to 72.
    {
      name = "WinSetOption";
      option = "filetype=git-.*";
      commands = ''
        set-option window autowrap_column 72
      '';
    }
  ];

  home.persistence."/persist${config.home.homeDirectory}".directories = [{
    method = "symlink";
    directory = "src";
  }];

  home.packages = [
    pkgs.git-open

    (pkgs.writeShellScriptBin "git-curlam" ''
      set -e

      b=$(git rev-parse HEAD)

      ${pkgs.curl}/bin/curl -Lf# "$@" \
          | ${config.programs.git.package}/bin/git am -q

      a=$(git rev-parse HEAD)

      git log --oneline --reverse "$b".."$a"
    '')
  ];
}

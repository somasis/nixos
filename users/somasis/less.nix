{ config
, pkgs
, ...
}: {
  home.sessionVariables = {
    # Colors for man pages
    # See terminfo(5) and <https://unix.stackexchange.com/a/108840> for tips
    LESS_TERMCAP_mb = ''$(tput sitm)''; # italicized text: italics
    LESS_TERMCAP_md = ''$(tput bold setaf 3)''; # headers: bold, yellow foreground
    LESS_TERMCAP_us = ''$(tput sitm setaf 2)''; # italicized text: italics, green foreground
    LESS_TERMCAP_so = ''$(tput bold rev)''; # search result highlighting: emboldened, inverted background

    LESS_TERMCAP_ue = ''$(tput sgr0)'';
    LESS_TERMCAP_me = ''$(tput sgr0)'';
    LESS_TERMCAP_se = ''$(tput sgr0)'';

    # less's XDG support uses $XDG_STATE_HOME/lesshst for some reason...
    LESSHISTFILE = "${config.xdg.cacheHome}/less/history";
    LESSHISTSIZE = "10000";
  };

  cache.directories = [{ method = "symlink"; directory = config.lib.somasis.xdgCacheDir "less"; }];

  programs.less = {
    enable = true;
    keys = ''
      #command
      /   forw-search
      ^F  forw-search

      # -i - Ignore case in searches if there's no uppercase characters in the pattern
      # -s - Combine multiple blank lines
      # -F - Quit if the whole thing can be viewed on one screen
      # -M - Show the lines and percentage of way through the input.
      # -R - "Like -r, but only ANSI "color" escape sequences are output in "raw" form."
      # --mouse - support mouse scrolling
      # --wheel-lines - only scroll 2 lines for each tick of the wheel
      # --incsearch - search as you type
      #
      # Removed:
      #   -X - don't print the initialization screen- i.e, don't clear the terminal
      #        Using -X caused scrolling inconsistencies on xterm. Patched in less
      #        v581, but it seems like Arch does not have that version yet...
      #        <https://github.com/gwsw/less/issues/24>
      #env
      LESS = -isMFR --mouse --wheel-lines=2
    '';
  };
}

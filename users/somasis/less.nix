{ config, ... }: {
  home.sessionVariables = {
    # Colors for man pages
    "LESS_TERMCAP_us" = ''$(printf '%b' "\033[3;32m")''; # italicized in asciidoctor
    "LESS_TERMCAP_mb" = ''$(printf '%b' "\033[3m")'';
    "LESS_TERMCAP_md" = ''$(printf '%b' "\033[1;33m")''; # sections, and bolded in asciidoctor
    "LESS_TERMCAP_me" = ''$(printf '%b' "\033[0m")'';
    "LESS_TERMCAP_se" = ''$(printf '%b' "\033[0m")'';
    "LESS_TERMCAP_so" = ''$(printf '%b' "\033[0m")'';
    "LESS_TERMCAP_ue" = ''$(printf '%b' "\033[0m")'';

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
    "LESS" = "-isMFR --mouse --wheel-lines=2";

    # XDG compliance
    "LESSHISTFILE" = "${config.xdg.cacheHome}/less/history";
  };

  home.persistence."/cache${config.home.homeDirectory}".directories = [{ directory = "var/cache/less"; method = "symlink"; }];

  programs.less.enable = true;
}

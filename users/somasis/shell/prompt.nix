{
  # prompt - Set variables such as $PS1, as well as readline configuration. See bash(1).

  programs.bash.initExtra = ''
    _before_command() {
        # stty -echo >&2
        local _before_command_command="''${BASH_COMMAND%% *}"
        case "$_before_command_command" in
            'sudo '*|'edo '*)
                _before_command_command="''${_before_command_command#* }"
                ;;
            '$'*)
                _before_command_command="''${_before_command_command#$}"
                _before_command_command="''${!_before_command_command}"
                ;;
            _*) return ;;
        esac

        printf '\e]0%s\a' "''${SSH_CONNECTION:+$USER@$HOSTNAME: }''${_before_command_command}"
        # stty echo >&2
    }

    _before_prompt() {
        local _before_prompt_error="$?"
        local _before_prompt_color="\e[1;32m"
        [ "$_before_prompt_error" -eq 0 ] || _before_prompt_color="\e[1;31m"
        stty -echo >&2

        PS1='\[\e[0m\e[34m\]\u'

        # Set terminal title.
        PS1="$PS1"'\[$(printf %b "\e]0;''${SSH_CONNECTION:+$USER@$HOSTNAME: }''${BASH##*/}: $PWD\a")\]'

        # Show hostname only over ssh(1) connections or chroots.
        [ -n "$SSH_CONNECTION" ] && PS1="$PS1"'@\[\e[0;35m\]\h\[\e[0m\]'

        PS1="$PS1"' \[\e[1;39m\]\w\[\e[0m\]'

        # git(1) prompt.
        PS1="$PS1 \[\e[1;33m\]$(_git_prompt)\[\e[0m\]"

        # Show exit status of last ran command.
        PS1="$PS1\[$_before_prompt_color\]∴\[\e[0m\] "
        stty echo >&2

        trap _before_command DEBUG
    }

    PROMPT_COMMAND="''${PROMPT_COMMAND:+; }_before_prompt"
  '';

  programs.readline = {
    enable = true;

    bindings = {
      "\\x08" = "unix-word-rubout"; # ctrl-backspace
    };

    variables = {
      # Use a single <tab> for completion, always; even when
      # there's multiple possible completions, and thus it's
      # ambiguous as to which is meant.
      show-all-if-ambiguous = true;

      # Append a symbol to the end of files in the completion list
      # (akin to `ls -F`).
      visible-stats = true;
      colored-stats = false;

      # When browsing history, move the cursor to the point it
      # was at when it was editing the entry in question.
      # history-preserve-point = true;

      # Briefly move the cursor over to a matching parenthesis
      # (for visibility).
      blink-matching-paren = true;

      menu-complete-display-prefix = true;
      mark-symlinked-directories = true;

      # Don't use readline's internal pager for showing completion;
      # just print them to the terminal.
      page-completions = false;
      print-completions-horizontally = true;

      # "when inserting a single match into the line ... [do] not
      # insert characters from the completion that match characters
      # after point in the word being completed, so [that] portions
      # of the word following the cursor are not duplicated."
      skip-completed-text = true;
    };
  };
}

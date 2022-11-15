{
  # prompt - Set variables such as $PS1. See sh(1).

  programs.bash.initExtra = ''
    _before_command() {
        # stty -echo >&2
        local _before_command_command="''${BASH_COMMAND%% *}"
        case "$_before_command_command" in
            'doas '*|'sudo '*)
                _before_command_command="''${_before_command_command#* }"
                ;;
            '$'*)
                _before_command_command="''${_before_command_command#$}"
                _before_command_command="''${!_before_command_command}"
                ;;
            _*) return ;;
        esac

        printf '\e]0%s\a' "''${SSH_CONNECTION:+$USER@$HOSTNAME: }''${BASH_COMMAND%% *}"
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
}

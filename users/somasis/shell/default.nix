{ pkgs, lib, ... }: {
  imports = [
    ./cd.nix
    ./commands.nix
    ./history.nix
    ./prompt.nix
  ];

  programs.bash = {
    enable = true;
    enableVteIntegration = true;

    sessionVariables = {
      IGNOREEOF = 1;
      TIMEFORMAT = ''
        wall	%3lR
        user	%3lU
        kern	%3lS
        cpu	%%P%
      '';
    };

    shellOptions = [
      "dirspell" # correct spelling of directory names during completion
      "checkjobs" # warn when trying to quit a shell with jobs running
      "globstar" # allow for using ** for recursive globbing
      "lithist" # save multi-line commands to the history with their newlines
    ];
  };

  programs.nix-index.enable = true;

  programs.bash.initExtra = lib.mkAfter (
    ""
    # Add automatic completion for aliases.
    + ''
      . ${pkgs.complete-alias}/bin/complete_alias
      complete -F _complete_alias ''${!BASH_ALIASES[@]}
    ''
    # s6/s6-rc bash completion.
    + ''
      . ${pkgs.fetchurl {
        url = "https://gist.githubusercontent.com/capezotte/45d9d5ebad50aa7419f632a43dad604e/raw/ad60df4d5bcb704a9b90ed9ed23a146d385c2b35/s6-comp.bash";
        hash = "sha256-DQySJr2Ci28RGFBH5VHSk1go7MCP/IhS8yHWOdTB4sI=";
      }}
    ''
  );

  # TODO: integrate system clipboard into bash readline yank/paste?
  # programs.bash.initExtra =
  #   let
  #     clip = "${pkgs.xclip}/bin/xclip -selection clipboard";
  #   in
  #   ''
  #     _xdiscard() {
  #         echo -n "''${READLINE_LINE:0:$READLINE_POINT}" | ${clip} -i
  #         READLINE_LINE="''${READLINE_LINE:$READLINE_POINT}"
  #         READLINE_POINT=0
  #     }
  #     _xcut_word() {
  #         word_length=${READLINE_LINE:0:$READLINE_POINT}
  #         word_length=${#word_length}
  #         echo -n "${READLINE_LINE:0:$READLINE_POINT}" | ${clip} -i
  #         bind backward-kill-word
  #     }
  #     _xkill() {
  #         echo -n "''${READLINE_LINE:$READLINE_POINT}" | ${clip} -i
  #         READLINE_LINE="''${READLINE_LINE:0:$READLINE_POINT}"
  #     }
  #     _xyank() {
  #         READLINE_LINE="''${READLINE_LINE:0:$READLINE_POINT}$(${clip} -o)''${READLINE_LINE:$READLINE_POINT}"
  #     }
  #     bind -m emacs -x '"\eh": _xcut_word'
  #     bind -m emacs -x '"\eu": _xdiscard'
  #     bind -m emacs -x '"\ek": _xkill'
  #     bind -m emacs -x '"\ey": _xyank'
  #   '';
}

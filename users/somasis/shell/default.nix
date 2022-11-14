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

    # Disable all default aliases
    shellAliases = { };
  };

  home.shellAliases = { };

  # TODO: this doesn't work :(
  # home.packages = [
  #   pkgs.complete-alias
  # ];
  programs.bash.initExtra = lib.mkAfter ''
    . ${pkgs.complete-alias}/bin/complete_alias
    complete -F _complete_alias ''${!BASH_ALIASES[@]}
  '';

  # TODO: integrate system clipboard into bash readline yank/paste
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

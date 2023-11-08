{ config
, pkgs
, ...
}:
let
  list = "${config.home.homeDirectory}/list/todo.txt";
in
{
  persist.directories = [{
    directory = "list";
    method = "symlink";
  }];

  home.shellAliases = {
    # Personal todo.txt aliases.
    todo-add = "list-add -f ${list}";
    todo-query = "list-query -f ${list}";
    todo-edit = "$EDITOR ${list}";
    todo = "todo-query -U";

    # Task list.
    task-query = "todo-query -l task";
    task-add = "todo-add -l task";
    task = "task-query -U";

    # University list.
    uni-query = "todo-query -l uni";
    uni-add = "todo-add -l uni";
    uni = "uni-query -U";

    # Grocery list.
    grocery-query = "todo-query -l grocery";
    grocery-add = "todo-add -l grocery";
    grocery = "grocery-query -U";

    # Wish list.
    wish-query = "todo-query -l wish";
    wish-add = "todo-add -l wish";
    wish = "wish-query -U";

    # Queue list.
    queue-query = "todo-query -l queue";
    queue-add = "todo-add -l queue";
    queue = "queue-query -U";
    listen-query = "todo-query -l queue -t listen";
    listen-add = "todo-add -l queue -t listen";
    listen = "listen-query -U";
    film-query = "todo-query -l queue -t film";
    film-add = "todo-add -l queue -t film";
    film = "film-query -U";
    tv-query = "todo-query -l queue -t tv";
    tv-add = "todo-add -l queue -t tv";
    tv = "tv-query -U";

    # Trip list.
    trip-query = "todo-query -l trip";
    trip-add = "todo-add -l trip";
    trip = "trip-query -U";
  };

  programs.bash.initExtra = ''
    list-query() {
        if [ -t 0 ] && [ -z "$NO_COLOR" ]; then
            command list-query "$@" | list-color
        else
            command list-query "$@"
        fi
    }
  '';

  # Integrate with list-add(1).
  programs.qutebrowser = {
    aliases.list-add =
      let
        list-add = pkgs.writeShellScript "list-add" ''
          set -eu
          set -o pipefail

          : "''${QUTE_FIFO:?}"
          exec >>"''${QUTE_FIFO}"

          title="$1"; shift
          url="$1"; shift

          attrs=$(dmenu -p "''${1:+\`}list-add''${1:+ $*\` }[''${title}]")
          [ $? -eq 1 ] && exit 0

          list-add -f ${list} "$@" "''${title} ''${url}''${attrs:+ ''${attrs}}"
        '';
      in
      "spawn -u ${list-add} {title} {url} -l wish";

    keyBindings.normal."ztw" = "list-add";
  };

  # programs.kakoune.plugins = [
  #   (pkgs.kakouneUtils.buildKakounePluginFrom2Nix {
  #     pname = "todotxt.kak";
  #     version = "unstable-2019-04-01";

  #     src = pkgs.fetchFromGitHub {
  #       owner = "nkoehring";
  #       repo = "kakoune-todo.txt";
  #       rev = "8856e0dfad09792c80dab07f1ae11e2f6b26cd95";
  #       hash = "sha256-b3Q8wWLu+L8/s0aI8exW5iiojfg8phaOWu4lnETflOo=";
  #     };
  #   })
  # ];
}

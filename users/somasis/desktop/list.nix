{ config
, pkgs
, ...
}:
let
  list = "${config.home.homeDirectory}/list/todo.txt";
in
{
  home.persistence."/persist${config.home.homeDirectory}".directories = [ "list" ];

  programs.bash.shellAliases = {
    # Personal todo.txt aliases.
    todo-add = "list-add -f ${list}";
    todo-query = "list-query -f ${list}";
    todo-edit = "$EDITOR ${list}";
    todo = "todo-query -U";

    # Task list.
    task-query = "todo-query -l task";
    task-add = "todo-add -l task";
    task = "task-query -U";

    # School list.
    school-query = "todo-query -l school";
    school-add = "todo-add -l school";
    school = "school-query -U";

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
  programs.qutebrowser.keyBindings.normal."ztw" =
    let
      listAdd = pkgs.writeShellScript "list-add" ''
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
    "spawn -u ${listAdd} {title} {url} -l wish";
}

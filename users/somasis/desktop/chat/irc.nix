{ config
, pkgs
, nixosConfig
, inputs
, lib
, ...
}:
let
  mkConfig = lib.generators.toKeyValue {
    listsAsDuplicateKeys = true;
    mkKeyValue = k: v:
      if builtins.isBool v then
        if v then
          "${lib.escape [ ''='' ] k}"
        else
          ""
      else
        lib.generators.mkKeyValueDefault { } " = " k v
    ;
  };

  catgirl = pkgs.catgirl.overrideAttrs (
    let
      year = builtins.substring 0 4 inputs.catgirl.lastModifiedDate;
      month = builtins.substring 4 2 inputs.catgirl.lastModifiedDate;
      day = builtins.substring 6 2 inputs.catgirl.lastModifiedDate;
    in
    oldAttrs:
    {
      name = "catgirl";
      version = "unstable-${year}-${month}-${day}";
      src = inputs.catgirl;
    }
  );

  catgirls = pkgs.writeShellApplication {
    name = "catgirls";
    runtimeInputs = [
      catgirl
      pkgs.coreutils
      pkgs.gnused
      pkgs.libnotify
      pkgs.tmux
    ];

    text = ''
      : "''${XDG_CONFIG_HOME:=$HOME/.config}"

      mode=tmux

      while getopts :cn arg >/dev/null 2>&1; do
          case "$arg" in
              c) mode=catgirl ;;
              n) mode=notify ;;
              *)
                  printf '%s\n' 'usage: catgirls [-cn] [catgirl arguments/notification arguments]' >&2
                  exit 69
                  ;;
          esac
      done
      shift $((OPTIND - 1))

      case "$mode" in
          catgirl)
              exec catgirl \
                  -u "${nixosConfig.networking.fqdnOrHostName}" \
                  -c "$XDG_CONFIG_HOME/catgirl/client-${nixosConfig.networking.fqdnOrHostName}.crt" \
                  -N "$0 -n" \
                  "$@"
              ;;

          notify)
              server=$(tr '\0' '\n' < /proc/"$PPID"/cmdline | tail -n1)
              server="''${server##*/}"; server="''${server%%.conf}"

              chat="$1"; shift
              if printf '%s\n' "$*" | grep -E "^(<\S+>|\* \S+)$(printf '\t')"; then
                  sender=$(printf '%s' "$1" \
                      | cut -f1 \
                      | sed -E '/^\* / s/^\* (\S+)/\1/; /^<\S+>/ s/^<(\S+)>/\1/')
                  message=$(printf '%s' "$1" | cut -f2-)
              else
                  sender=
                  message="$*"
              fi
              shift

              [[ "$chat" == "$sender" ]] && sender=
              message=$(printf '%s' "$message" | sed 's/</\&lt;/g;s/>/\&gt;/g')

              id=$(
                  printf '%s' "$chat" \
                      | sha1sum \
                      | tr -cd '1-9' \
                      | cut -c-8
              )

              action=$(
                 notify-send \
                      -a catgirl \
                      -i irc-chat \
                      -A 'Read' \
                      -r "$id" \
                      -- \
                      "$chat" \
                      "''${sender:+&lt;$sender&gt; }$message"
              ) || exit 0

              exec >/dev/null 2>&1

              # oh this is disgusting i LOVE IT
              case "$action" in
                  'Read')
                      "$0" find-window -N "$server" \; send-keys Down Enter
                      "$0" send-keys M-0 End C-u
                      "$0" send-keys -l "/window $chat"
                      "$0" send-keys Enter C-y
                      jumpapp -t catgirl -c catgirl alacritty --class catgirl -T catgirl -e "$0"
                      ;;
              esac

              exit $?
              ;;
      esac

      [[ $# -eq 0 ]] && set -- attach-session

      exec tmux -L catgirls -f "$XDG_CONFIG_HOME"/tmux/catgirls.conf "$@"
    '';
  };

  catgirls-uri = pkgs.writeShellApplication {
    name = "catgirls-uri";
    runtimeInputs = [
      catgirl
      catgirls
      pkgs.coreutils
    ];

    text = ''
      c() {
          local k="$1"
          shift
          local v="$*"

          printf '%s = %s\n' "$k" "$v" >>"$config"
      }

      warn() {
          warned=true
          printf 'warning: %s\n' "$@" >&2
      }

      prompt() {
          printf "%s: " "$1" >&2
          read -r -s prompt
          printf '%s' "$prompt"
          unset prompt
      }

      config=$(mktemp)

      uri="$1"

      case "$uri" in
          'ircs:' | 'irc:' | 'ircs://' | 'irc://' | 'ircs:///' | 'irc:///')
              protocol=''${uri%%:*}

              base=irc.tilde.chat
              channels='#ascii.town'
              ;;
          'ircs:///'* | 'irc:///'*)
              protocol=''${uri%%://*}

              base=irc.tilde.chat

              remain=''${uri#"$protocol":///}
              remain=''${remain#*///}
              ;;
          'ircs://'* | 'irc://'*)
              protocol=''${uri%%://*}

              base=''${uri#"$protocol"://}
              base=''${base%%/*}

              remain=''${uri#"$protocol"://}
              remain=''${remain#*/}
              ;;
          *)
              printf "error: invalid uri: '%s'\n" "$uri" >&2
              exit 1
              ;;
      esac

      case "$remain" in
          *'?'*)
              string=''${remain#*\?}
              remain=''${remain%\?*}
              ;;
      esac

      case "$base" in
          '['*']')
              server="$base"
              ;;
          *':'*'@'*)
              server=''${base#*@}

              nick=''${base%@*}
              nick=''${nick%%:*}

              nick_pass=''${base#*:}
              nick_pass=''${nick_pass%@*}
              ;;
          *':'*)
              port=''${base##*:}
              server=''${base%:"$port"}
              ;;
          *'@'*)
              server=''${base#*@}
              nick=''${base%@*}
              ;;
          *)
              # echo "base: $base" >&2
              server="$base"
              ;;
      esac

      [[ "$base" == "$remain" ]] && remain=

      c host "$server"
      c port "''${port:-6697}"

      if [[ -n "$string" ]]; then
          IFS='&'
          # shellcheck disable=SC2086
          set -- $string
          unset IFS

          while [[ $# -gt 0 ]]; do
              case "$1" in
                  'key='*)
                      keys="''${1#*=},$keys"
                      ;;
                  *)
                      warn "unsupported attribute: $1"
                      ;;
              esac
              shift
          done
      fi

      if [[ -n "$remain" ]]; then
          IFS=,
          # shellcheck disable=SC2086
          set -- $remain
          unset IFS

          while [[ $# -gt 0 ]]; do
              case "$1" in
                  *'!'*'@'*)
                      query_nick=''${1%%!*}

                      query_user=''${1#*!}
                      query_user=''${query_user%@*}

                      warn "unsupported feature: querying nick '$1'; execute '/query $query_nick' at startup"
                      ;;

                  'isserver' | 'ischannel') : ;;
                  'needpass')
                      server_password=$(prompt "password for '$server'")
                      c pass "$server_password"
                      ;;

                  'isnick')
                      warn "unsupported: $1"
                      isnick=true
                      ;;

                  'is'* | 'need'*) warn "unsupported: $1" ;;

                  '#'*)
                      channels="$1''${channels:+,$channels}"
                      ;;
                  *)
                      [[ "$isnick" = "true" ]] && continue
                      [[ -n "$1" ]] && channels="#$1''${channels:+,$channels}"
                      ;;
              esac
              shift
          done
      fi

      if [[ -n "$nick" ]]; then
          c nick "$nick"
          [[ -n "$nick_pass" ]] && c sasl-plain "$nick:$nick_pass"
      fi

      [[ -n "$channels" ]] && c join "$channels''${keys:+ $keys}"

      if [[ "$warned" == "true" ]]; then
          printf 'press any key to continue...' >&2
          read -r -s -n 1
      fi

      trap 'rm -f "$config"' EXIT
      tmux -L catgirls -f "$XDG_CONFIG_HOME"/tmux/catgirls.conf \
          new-window -n "$server" -- "$0" -c "$config"
      exit $?
    '';
  };

  catgirls-spoiler = pkgs.writeShellApplication {
    name = "catgirls-spoiler";
    runtimeInputs = [
      pkgs.coreutils
      pkgs.tmux
    ];

    text = ''
      : "''${XDG_CONFIG_HOME:=$HOME/.config}"
      : "''${XDG_RUNTIME_DIR:=/tmp/$(id -un)}"

      usage() {
          printf 'usage: %s [-c] NETWORK\n' "''${0##*/}" >&2
          exit 69 # EX_USAGE
      }

      clean() { rm -rf "$runtime"; }

      runtime="$XDG_RUNTIME_DIR/catgirls-spoiler"
      mkdir -p "$runtime"

      [ "$1" = '-c' ] && clean

      [ $# -lt 1 ] && usage

      # Provide black fg/black bg toggling as a "spoiler function"
      if [ -f "$runtime"/spoiler-"$1" ]; then
          tmux -L catgirls -f "''$XDG_CONFIG_HOME"/tmux/catgirls.conf send-keys C-z c
          exec rm -f "$runtime"/spoiler-"$1"
      else
          tmux -L catgirls -f "$XDG_CONFIG_HOME"/tmux/catgirls.conf send-keys C-z s
          exec touch "$runtime"/spoiler-"$1"
      fi
    '';
  };
in
{
  home.packages = [
    catgirl
    catgirls
    catgirls-uri
    catgirls-spoiler
  ];

  xdg.configFile."tmux/catgirls.conf".text = ''
    # tmux -L catgirls -f ~/etc/tmux/catgirls.conf attach-session
    new-session -t catgirls

    source "$XDG_CONFIG_HOME/tmux/tmux.conf"

    # Don't allow 256-color palettes, as I don't like how dark some of the colors are.
    set-option -g default-terminal "tmux"

    # Match `catgirl`'s status style
    set-option -g status           on
    set-option -g status-position  top

    set-option -g status-justify   left
    set-option -g status-left      ""
    set-option -g status-right     ""
    set-option -g status-interval  5

    set-option -g window-status-format         " #I #T "
    set-option -g window-status-current-format " #I #T "
    set-option -g window-status-separator      ""

    # Default styles. `catgirls` will set per-window styles.
    set-option -g status-style                 "bg=terminal,fg=terminal"
    set-option -g status-left-style            "fg=magenta"
    set-option -g status-right-style           "fg=magenta"
    set-option -g window-status-style          "bg=terminal,fg=terminal"
    set-option -g window-status-current-style  ""
    set-option -g window-status-activity-style "bold"
    set-option -g exit-empty                   on

    # Ignore bells, only check for activity.
    # Notifications from highlights are handled by `catgirls`.
    set-option -g monitor-activity  on
    set-option -g monitor-bell      on
    set-option -g visual-activity   off
    set-option -g visual-bell       off

    set-option -g set-titles        on              # Refers to *terminal window title*.
    set-option -g set-titles-string "catgirl: #T"

    # Set window title rules.
    set-option -g automatic-rename  off
    set-option -g allow-rename      off
    set-option -g renumber-windows  on

    # Clients exit on network errors, restart them automatically
    # (use `kill-pane'/`C-_ x' to destroy windows)
    set-option -g remain-on-exit    on
    set-hook -g   pane-died         respawn-pane

    # Disable scrollback. `catgirl` has its own.
    set-option -g history-limit     0

    # Fix redrawing.
    set-hook -g   client-resized    "send-keys C-l"

    # Keybinds.

    ## Disable menus.
    unbind-key -T root MouseDown3Pane           # Right click is not useful since scrollback is off.
    unbind-key -T root M-MouseDown3Pane

    ## tmux // Prefix // control + b (C-_)
    # unbind-key -T prefix C-b                    # Used by `catgirl` for formatting.
    # set-option -g prefix                'C-b'

    ## Text editing // Move to word left of cursor // meta + b control + left
    ## Text editing // Move to word right of cursor // meta + f, control + right
    ## Text editing // Delete word to left of cursor // control + w, control + h, control + backspace
    ## Text editing // Delete word to right of cursor // meta + d, control + delete
    bind-key -n     C-Left              send-keys M-b
    bind-key -n     C-Right             send-keys M-f
    bind-key -n     C-h                 send-keys C-w
    bind-key -n     C-Delete            send-keys M-d

    ## Text editing // Toggle bold // meta + z + b, meta + b
    ## Text editing // Toggle italics // meta + z + i, meta + i
    ## Text editing // Toggle underline // meta + z + u, meta + u
    ## Text editing // Insert color marker // meta + c
    bind-key -n     M-b                 send-keys C-z b
    bind-key -n     M-i                 send-keys C-z i
    bind-key -n     M-u                 send-keys C-z u
    bind-key -n     M-c                 send-keys C-z c

    ## Text editing // Toggle spoiler // meta + s
    bind-key -n     M-s                 run-shell "catgirls-spoiler #W"
    bind-key -n     M-S                 send-keys M-s

    # Disarm Control-C
    bind-key -n -N 'confirm interrupt'  -- C-c confirm-before -p 'Send ^C? (y/N)' -- 'send-keys -- C-c'

    # add buffer scrolling via mouse (by two lines)
    bind-key -n WheelUpPane     send-keys Up Up
    bind-key -n WheelDownPane   send-keys Down Down

    ## Windows // Switch to window [number] // control + [0-9]
    bind-key -n C-0     select-window -t 0
    bind-key -n C-1     select-window -t 1
    bind-key -n C-2     select-window -t 2
    bind-key -n C-4     select-window -t 4
    bind-key -n C-5     select-window -t 5
    bind-key -n C-6     select-window -t 6
    bind-key -n C-7     select-window -t 7
    bind-key -n C-8     select-window -t 8
    bind-key -n C-9     select-window -t 9

    ## Windows // Cycle through server windows // meta + tab
    set-option -gw      xterm-keys on
    bind-key -n M-Tab   next-window
    bind-key -n M-S-Tab next-window

    ## Windows // Move to {previous,next} channel window // meta + left, meta + right
    bind-key -n M-Left  send-keys C-p
    bind-key -n M-Right send-keys C-n

    ## Commands // Execute /open // control + o
    bind-key -n C-o { send-keys C-e C-u; send-keys -l "/open"; send-keys Enter; send-keys C-y; }

    ## Commands // /query kylie // control + f
    bind-key -n C-f { send-keys C-e C-u; send-keys -l "/query kylie"; send-keys Enter; send-keys C-y; }

    ## Commands // Close current window // control + w
    bind-key -n C-w { send-keys C-e C-u; send-keys -l "/close"; send-keys Enter; send-keys C-y; }

    ## State // Quit all servers // control + q
    bind-key -n C-q kill-session -t catgirls

    ## State / Reconnect server // control + r
    bind-key -n -N "reconnect network" -- C-r confirm-before -p 'reconnect network? (y/N)' -- 'respawn-pane -k'

    # Networks.

    new-window -n tilde --      catgirls -c tilde.pounce.somas.is.conf
    set-option -a window-status-style "bg=terminal,fg=magenta"
    set-option -a window-status-current-style "bg=terminal,fg=magenta,reverse"
    set-option -a window-status-activity-style "bg=terminal,fg=magenta"

    new-window -n libera --     catgirls -c libera.pounce.somas.is.conf
    set-option -a window-status-style "bg=terminal,fg=blue"
    set-option -a window-status-current-style "bg=terminal,fg=blue,reverse"
    set-option -a window-status-activity-style "bg=terminal,fg=blue"

    new-window -n oftc --       catgirls -c oftc.pounce.somas.is.conf
    set-option -a window-status-style "bg=terminal,fg=yellow"
    set-option -a window-status-current-style "bg=terminal,fg=yellow,reverse"
    set-option -a window-status-activity-style "bg=terminal,fg=yellow"

    # new-window -n bitlbee --    catgirls -c bitlbee.conf
    # set-option -a window-status-style "bg=terminal,fg=green"
    # set-option -a window-status-current-style "bg=terminal,fg=green,reverse"
    # set-option -a window-status-activity-style "bg=terminal,fg=green"

    # Delete the default shell window that is spawned by tmux.
    kill-window -t 0

    select-window -t 0
  '';

  xdg.desktopEntries.catgirls-uri = {
    name = "catgirls-uri";
    genericName = "ilo toki IRC";
    icon = "irc-chat";
    categories = [ "Network" "Chat" "InstantMessaging" "IRCClient" "ConsoleOnly" ];

    exec = "${catgirls-uri} %U";
    terminal = true;
    mimeType = [
      "x-scheme-handler/irc"
      "x-scheme-handler/ircs"
    ];
  };

  persist.files = [
    "etc/catgirl/client-${nixosConfig.networking.fqdnOrHostName}.crt"
    # "share/catgirl/bitlbee.pounce.somas.is.buf"
    "share/catgirl/libera.pounce.somas.is.buf"
    "share/catgirl/oftc.pounce.somas.is.buf"
    "share/catgirl/tilde.pounce.somas.is.buf"
  ];

  xdg.configFile = {
    # "catgirl/bitlbee.pounce.somas.is.conf".text = ''
    #   host = bitlbee.pounce.somas.is
    #   sasl-external
    #   save = bitlbee.pounce.somas.is.buf
    #   highlight = root!*@* PRIVMSG #twitter_* You: \[[0123456789abcdef][0123456789abcdef]->[0123456789abcdef][0123456789abcdef]\]
    # '';

    "catgirl/libera.pounce.somas.is.conf".text = mkConfig {
      host = "libera.pounce.somas.is";
      sasl-external = true;

      save = "libera.pounce.somas.is.buf";

      ignore = [ "* [JPQM][OAU][IRD][NTE] #*" ];
    };

    "catgirl/oftc.pounce.somas.is.conf".text = mkConfig {
      host = "oftc.pounce.somas.is";
      user = "kylie";
      sasl-external = true;

      save = "oftc.pounce.somas.is.buf";

      ignore = [ "* [JPQM][OAU][IRD][NTE] #*" ];
    };

    "catgirl/tilde.pounce.somas.is.conf".text = mkConfig {
      host = "tilde.pounce.somas.is";
      sasl-external = true;

      save = "tilde.pounce.somas.is.buf";

      ignore = [
        "* [JPQM][OAU][IRD][NTE] #*"
        "tildebot!*@* PRIVMSG * \[*Karma*\]*"
        "tildebot!*@* PRIVMSG * \[*Demojize*\]*"
        "tildebot!*@* PRIVMSG * \[*Ducks*\]*"
        "tildebot!*@* PRIVMSG * \[*Sed*\]*"
        "sedbot"
        "downgrade"
        "tildebot!*@* PRIVMSG #meta \[*Tilderadio*\]*"
        "tildecraft_mc_bot_v1!*@* PRIVMSG #minecraft *"
      ];
    };
  };

  services.dunst.settings = {
    zz-catgirl = {
      appname = "catgirl";
      background = config.xresources.properties."*color2";
    };

    zz-catgirl-channel-cassie = {
      appname = "catgirl";
      body = "<cassie>*";
      background = "#7596ff";
      foreground = "#ffffff";
    };

    zz-catgirl-dm-cassie = {
      appname = "catgirl";
      summary = "<cassie>*";
      background = "#7596ff";
      foreground = "#ffffff";
    };

    zz-catgirl-channel-june = {
      appname = "catgirl";
      body = "<june>*";
      background = "#995b6b";
      foreground = "#ffffff";
    };

    zz-catgirl-dm-june = {
      appname = "catgirl";
      summary = "<june>*";
      background = "#995b6b";
      foreground = "#ffffff";
    };
  };

  somasis.tunnels.tunnels = [{
    name = "scooper";
    location = 9400;

    remote = "somasis@lacan.somas.is";
  }];

  services.sxhkd.keybindings."super + c" = "${pkgs.jumpapp}/bin/jumapp -t catgirl -c catgirl alacritty --class catgirl -T catgirl -e catgirls";
}

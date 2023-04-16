{ config
, pkgs
, ...
}:
let
  ledgerRelative = "ledger";
  ledgerAbsolute = "${config.home.homeDirectory}/${ledgerRelative}";

  ledger-bills = pkgs.writeShellApplication {
    name = "ledger-bills";
    runtimeInputs = [
      pkgs.gnugrep
      # TODO pkgs.khal
    ];

    text = ''
      : "''${NO_COLOR:=}"
      [ -z "''${NO_COLOR}" ] && [ -t 0 ] && khal() { command khal --color "$@"; }

      [ $# -gt 0 ] && set -- today 1d

      khal list \
          -a Ledger \
          --day-format "{bold}{date-long}" \
          --format "    {location}{nl}        {calendar-color}{title}{nl}            {description}{reset}" \
          "$@" 2>/dev/null \
          | grep -v 'No events'
    '';
  };

  ledger-charts = pkgs.writeShellApplication {
    name = "ledger-charts";
    runtimeInputs = [
      pkgs.gnuplot
      pkgs.ncurses
    ];

    text = ''
      plot() {
          (
              cat <<EOF
      set terminal ''${led_terminal}

      set title   "$1"
      set xdata   time
      set timefmt "%Y-%m-%d"

      plot "-" using 1:2 with lines
      EOF
              ledger -J register "$@"
          )   | gnuplot

      }

      cols=$(tput cols)
      lines=$(tput lines)

      [ "''${cols}" -gt 120 ] && cols=120
      [ "''${lines}" -gt 30 ] && lines=30

      led_terminal="dumb ansi size ''${cols},''${lines}"

      if [ "$#" -gt 0 ]; then
          while [ "$#" -gt 0 ]; do
              plot "$1"
              shift
          done
      else
          plot assets:checking
      fi
    '';
  };

  ledger-edit = pkgs.writeShellApplication {
    name = "ledger-edit";

    runtimeInputs = [
      pkgs.coreutils
      pkgs.findutils
    ];

    text = ''
      while :; do
          # shellcheck disable=SC2046
          ''${EDITOR:-vi} \
              "${ledgerAbsolute}"/transactions.ledger \
              "+$edit_line" \
              $(
                  find -H "${ledgerAbsolute}"// \
                      -type f \
                      ! -path '*//[0123456789][0123456789][0123456789][0123456789]/*' \
                      ! -name '.*' \
                      ! -name 'transactions.ledger' \
                      ! -path '*/.*' \
                      | sort
              )

          if ledger source; then
              edit_line=
              break
          else
              edit_line=$(
                  ledger source 2>&1 >/dev/null \
                      | sed -E '/^While parsing.*line /!d; s/.*line ([0-9]+):/\1/' \
                      | head -n1
              )

              while :; do
                  edit=$(prompt "Error in journal, edit again?" Y/n)
                  case "''${edit}" in
                      [Yy])
                          continue 2
                          ;;
                      [Nn])
                          break 2
                          ;;
                      *)
                          printf 'Invalid response.\n' >&2
                          ;;
                  esac
              done
          fi
      done
      ledger
    '';
  };

  ledger-interactive = pkgs.writeShellApplication {
    name = "ledger-interactive";

    runtimeInputs = [ pkgs.tmux ];

    text = ''
      exec tmux -L ledger -f "''${XDG_CONFIG_HOME}"/tmux/ledger.conf attach-session
    '';
  };

  ledger-iwatch = pkgs.writeShellApplication {
    name = "ledger-iwatch";

    runtimeInputs = [
      pkgs.findutils
      pkgs.rwc
      pkgs.xe
    ];

    text = ''
      ledger "$@"
      find -H "${ledgerAbsolute}" -type f \
          | rwc -p \
          | xe -s '"$@"' ledger "$@"
    '';
  };

  ledger-new = pkgs.writeShellApplication {
    name = "ledger-new";

    runtimeInputs = [
      pkgs.gnused
      pkgs.coreutils
      pkgs.moreutils
    ];

    text = ''
      [ $# -eq 0 ] && exec ledger edit

      ledger entry "$@" >/dev/null || exit $?
      entry=$(ledger entry "$@" | sed 's/\$-/-\$/')
      while :; do
          printf '%s\n' "''${entry}"
          add=$(prompt "Add to transactions.ledger?" Y/n/e)
          case "''${add}" in
              [Ee])
                  printf '\n' >&2
                  entry=$(printf '%s\n' "''${entry}" | vipe --suffix=.ledger)
                  ;;
              [Yy] | "")
                  [ -n "$(tail -n1 "${ledgerAbsolute}"/transactions.ledger)" ] && printf '\n' >>"${ledgerAbsolute}"/transactions.ledger
                  printf '%s\n' "''${entry}" >>"${ledgerAbsolute}"/transactions.ledger
                  break
                  ;;
              [Nn])
                  break
                  ;;
              *)
                  printf 'Invalid response.\n' >&2
                  ;;
          esac
      done
      led
    '';
  };

  ledger-new-transaction = pkgs.writeShellApplication {
    name = "ledger-new-transaction";
    runtimeInputs = [
      pkgs.coreutils
      pkgs.rlwrap
    ];

    text = ''
      usage() {
          cat >&2 <<EOF
      usage: ledger new-transaction [-{p,t}{i,c}] [-pr REGEX] [-pn NAME] [-td DATE]
                                  [-te DATE] [-tn NAME] posting[=prefill_amount]...
      EOF
          exit 69
      }

      # shellcheck disable=SC2059
      print() {
          printf "$@" >&2
          printf "$@" >>"''${f}"
      }

      transaction() {
          print '%s %s%s\n' "''${1}" "''${2}" "''${3}"
      }

      posting() {
          print '    %s  \t%s\n' \
              "''${1:=$(rlwrap ''${2:+-P "$2"} -S "$(printf '    * ')"  -a -o cat)}" \
              "$(rlwrap ''${2:+-P "$2"} -S "$(printf '    * %s  \t' "''${1}")" -a -o cat)"
      }

      ts=
      td=$(date +%Y-%m-%d)
      te=
      tn="Unnamed transaction"

      while getopts :t: arg >/dev/null 2>&1; do
          echo "''${arg}"
          case "''${arg}" in
              t)
                  echo "''${OPTARG}"
                  case "''${OPTARG:0:1}" in
                      c) ts='* ' ;;
                      d) td="''${OPTARG:1}" ;;
                      e) te="''${OPTARG:1}" ;;
                      i) ts='! ' ;;
                      n) tn="''${OPTARG:1}" ;;
                      *) usage ;;
                  esac
                  ;;
              # p)
              #     case "''${OPTARG:0:1}" in
              #         c) ps='* ' ;;
              #         i) ps='! ' ;;
              #         n) pn="''${OPTARG:1}" ;;
              #         *) usage ;;
              #     esac
              #     ;;
              *) usage ;;
          esac
      done
      shift $((OPTIND - 1))

      f=$(mktemp)

      # shellcheck disable=SC2119
      transaction "''${te:+''${te}=}''${td}" "''${ts}" "''${tn}"

      while [ "$#" -gt 0 ]; do
          case "''${1}" in
              *=*) posting "''${1%=*}" "''${1#*=}" ;;
              *)   posting "$1" ;;
          esac
          shift
      done

      cat "''${f}"

      rm -f "''${f}"
    '';
  };

  ledger-overview = pkgs.writeShellApplication {
    name = "ledger-overview";

    text = ''
      ledger bal --flat --no-total "$@" ^assets: ^liabilities: ^job:
      ledger bal --flat --no-total --pending "$@" ^income:
      ledger bal --flat --no-total "$@" ^owed:
      printf '\n'

      ledger bills 1d
    '';
  };

  ledger-prices = pkgs.writeShellApplication {
    name = "ledger-prices";
    runtimeInputs = [
      pkgs.coreutils
      pkgs.gnused
    ];

    text = ''
      date=$(date +'%Y-%m-%d %H:%M:%S')

      sed '/^commodity\s*[A-Z]/!d; s/^commodity\s*//; s/\s.*//' "${ledgerAbsolute}"/commodities.ledger \
          | while read -r currency; do
              currency_to_usd=
              while [[ -z "''${currency_to_usd}" ]]; do
                  currency_to_usd=$(autocurl -sf "https://usd.rate.sx/1''${currency}")
                  sleep 1
              done

              printf 'P %s %s %s\n' "''${date}" "''${currency}" "\$''${currency_to_usd}"
          done
    '';
  };

  ledger-timeclock = pkgs.writeShellApplication {
    name = "ledger-timeclock";
    runtimeInputs = [
      pkgs.coreutils
      pkgs.dateutils
    ];

    text = ''
      time="''${1:-now}"

      read -r s d t a p <<EOF
      $(tail -n1 "${ledgerAbsolute}"/timeclock.ledger)
      EOF

      date=$(date +%Y-%m-%d)
      time=$(dateconv -f %H:%M:%S -z "''${TZ:-/etc/localtime}" "''${time}")
      time=$(dateround -f %H:%M:%S "''${time}" 29s)
      echo "''${time}"

      case "''${s}" in
          i)
              # printf 'o %s %s %s\n' "''${date}" "''${time}" "''${a}''${p:+ ''${p}}" >>"${ledgerAbsolute}"/timeclock.ledger
              ;;
          o)
              # printf 'i %s %s %s\n' "''${date}" "''${time}" "''${a}''${p:+ ''${p}}" >>"${ledgerAbsolute}"/timeclock.ledger
              ;;
          *)
              exit
              ;;
      esac

      diff=$(dateconv -f %Y-%M-%dT%H:%M:%S -z "''${TZ:-/etc/localtime}" "''${d}T''${t}")
      diff=$(datediff -i %Y-%M-%dT%H:%M:%S -f %Hh%Mm "''${diff}" "''${date}T''${time}")
      t12=$(date --date="''${time}" +"%I:%M%p")
      case "''${s}" in
          i)
              printf '%s: finish work: %s since %s %s\n' \
                  "''${a}''${p:+ ''${p}}" \
                  "''${diff}" \
                  "''${d}" \
                  "''${t12}"
              ;;
          o)
              printf '%s: begin work: %s\n' \
                  "''${a}''${p:+ ''${p}}" \
                  "''${t12}"
              ;;
      esac
    '';
  };
in
{
  home.persistence."/persist${config.home.homeDirectory}".directories = [{
    directory = "${ledgerRelative}";
    method = "symlink";
  }];

  programs.ledger = {
    enable = true;

    extraConfig = ''
      --strict
      --date-format %Y-%m-%d
      --time-colon
    '';

    package = pkgs.symlinkJoin {
      name = "ledger-final";

      paths = [
        (pkgs.buildEnv {
          name = "ledger-doc";
          paths = [ pkgs.ledger ];
          pathsToLink = [ "/share/man" ];
        })

        (pkgs.writeShellApplication {
          name = "ledger";
          runtimeInputs = [
            pkgs.ledger
            pkgs.moreutils

            ledger-bills
            ledger-charts
            ledger-edit
            ledger-interactive
            ledger-iwatch
            ledger-new
            ledger-new-transaction
            ledger-overview
            ledger-prices
            ledger-timeclock
          ];

          text = ''
            ledger() { "''${0}" "$@"; }

            : "''${XDG_CONFIG_HOME:=''${HOME}/.config}"
            : "''${LEDGER_FILE:="${ledgerAbsolute}/journal.ledger"}"

            export LEDGER_FILE

            prompt() {
                if [ $# -eq 1 ]; then
                    printf '%s: ' "$1" >&2
                else
                    printf '%s [%s]: ' "$1" "$2" >&2
                fi
                read -r prompt
                [ $# -gt 1 ] && [ -z "''${prompt}" ] && prompt="''${2}"
                printf '%s' "''${prompt}"
            }

            case "''${1:-}" in
                "")
                    if command -v ledger-overview >/dev/null 2>&1; then
                        # shellcheck disable=SC1090
                        # don't try to follow source
                        source "$(command -v ledger-overview)"
                    else
                        exec ledger
                    fi
                    ;;
                *)
                    if command -v ledger-"$1" >/dev/null 2>&1; then
                        c="$1"
                        shift

                        # shellcheck disable=SC1090
                        # don't try to follow source
                        source "$(command -v ledger-"''${c}")"
                    else
                        exec ledger "$@"
                    fi
                    ;;
            esac
          '';
        })
      ];
    };
  };
}

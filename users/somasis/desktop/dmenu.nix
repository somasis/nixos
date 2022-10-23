{ config
, nixosConfig
, lib
, pkgs
, ...
}:
let
  dmenu-flexipatch = (
    pkgs.stdenv.mkDerivation rec {
      pname = "dmenu-flexipatch";
      version = "5.1.20220314";

      src = pkgs.fetchFromGitHub {
        owner = "bakkeby";
        repo = "dmenu-flexipatch";
        rev = "b210a99e318e6724b9823eb48149704c006d2282";
        hash = "sha256-tTWm+AYJvc5xbXnR1mM2uThwqmUq0F3nUVi79XgZq88=";
      };

      buildInputs = [
        pkgs.xorg.libX11
        pkgs.xorg.libXinerama
        pkgs.zlib

        # Necessary for dmenu to use emojis properly.
        pkgs.pango
        (pkgs.xorg.libXft.overrideAttrs (oldAttrs: {
          patches = [
            (pkgs.fetchpatch {
              url = "https://gitlab.freedesktop.org/xorg/lib/libxft/merge_requests/1.patch";
              sha256 = "sha256-MfPOOhruG6XHt5ABpXi/oEiy8nfVGWVsq4zqjXbAtW4=";
            })
          ];
        }))
      ];

      nativeBuildInputs = [ pkgs.pkg-config ];

      postPatch = ''
        sed -ri -e 's!\<(dmenu|dmenu_path|stest)\>!'"$out/bin"'/&!g' dmenu_run
        sed -ri -e 's!\<stest\>!'"$out/bin"'/&!g' dmenu_path
      '';

      preConfigure = ''
        sed -i \
          -e "s@PREFIX = /usr/local@PREFIX = $out@g" \
          -e "s@^#PANGO@PANGO@" \
          config.mk
          # -e 's@"monospace:size=10"@"monospace:size=11", "emoji:size=11"@' \

        cat > patches.h <<EOF
        #define ALPHA_PATCH            1
        #define COLOR_EMOJI_PATCH      1
        #define CTRL_V_TO_PASTE_PATCH  1
        #define GRIDNAV_PATCH          1
        #define GRID_PATCH             1
        #define HIGHLIGHT_PATCH        1
        #define INITIALTEXT_PATCH      1
        #define INSTANT_PATCH          1
        #define LINE_HEIGHT_PATCH      1
        #define MOUSE_SUPPORT_PATCH    1
        #define NO_SORT_PATCH          1
        #define PANGO_PATCH            1
        #define PLAIN_PROMPT_PATCH     1
        #define VERTFULL_PATCH         1
        #define WMTYPE_PATCH           1
        // #define DYNAMIC_OPTIONS_PATCH  1
        // #define FUZZYHIGHLIGHT_PATCH   1
        // #define FUZZYMATCH_PATCH       1
        // #define MANAGED_PATCH          1
        // #define NUMBERS_PATCH          1
        // #define PASSWORD_PATCH         1
        // #define PREFIXCOMPLETION_PATCH 1
        // #define PRESELECT_PATCH        1
        // #define PRINTINDEX_PATCH       1
        // #define REJECTNOMATCH_PATCH    1
        // #define RESTRICT_RETURN_PATCH  1
        // #define TSV_PATCH              1
        // #define WMTYPE_PATCH           1
        // #define XRESOURCES_PATCH       1
        EOF
      '';

      makeFlags = [ "CC:=$(CC)" "PKG_CONFIG:=$(PKG_CONFIG)" ];

      meta = with pkgs.lib; {
        description = "A generic, highly customizable, and efficient menu for the X Window System";
        license = with licenses; [ mit ];
        maintainers = with maintainers; [ somasis ];
        platforms = platforms.all;
      };
    }
  );

  dmenu = (pkgs.writeShellApplication {
    name = "dmenu";

    runtimeInputs = [ dmenu-flexipatch ];
    text = ''
      exec dmenu \
        -o 0 \
        -h 48 \
        -fn "monospace 10" \
        -nb "${config.xresources.properties."*darkBackground"}" \
        -nf "${config.xresources.properties."*darkForeground"}" \
        -sb "${config.xresources.properties."*colorAccent"}" \
        -sf "${config.xresources.properties."*darkForeground"}" \
        -nhb "${config.xresources.properties."*darkBackground"}" \
        -nhf "${config.xresources.properties."*color1"}" \
        -shb "${config.xresources.properties."*colorAccent"}" \
        -shf "${config.xresources.properties."*color1"}" \
        "$@"
    '';
  });

  dmenu-emoji = (
    pkgs.writeShellApplication {
      name = "dmenu-emoji";

      runtimeInputs = [
        dmenu
        pkgs.coreutils
        pkgs.gnused
        pkgs.moreutils
        pkgs.unicode-emoji
        pkgs.uq
        pkgs.xclip
        pkgs.xdotool
      ];

      text = ''
        : "''${DMENU_EMOJI_LIST:=${pkgs.unicode-emoji}/share/unicode/emoji/emoji-test.txt}"
        : "''${DMENU_EMOJI_RECENT:=''${XDG_CACHE_HOME:=~/.cache}/dmenu/''${0##*/}.cache}"

        usage() {
            cat >&2 <<EOF
        usage: ''${0##*/} [-clt]
        EOF
            exit 69
        }

        list() {
            {
                cat "$DMENU_EMOJI_RECENT" 2>/dev/null
                sed -E \
                    -e '/; fully-qualified/!d' \
                    -e 's/.* # //' \
                    -e 's/E[0-9]+\.[0-9]+ //' \
                    -e 's/&/\&amp;/' \
                    "$DMENU_EMOJI_LIST" \
                    | sort
            } | uq
        }

        clip=false
        list=false
        type=false

        while getopts :clt arg >/dev/null 2>&1; do
            case "$arg" in
                c) clip=true ;;
                l) list=true ;;
                t) type=true ;;
                ?)
                    printf 'unknown argument -- %s\n' "$OPTARG" >&2
                    usage
                    ;;
            esac
        done
        shift $((OPTIND - 1))

        mkdir -p "''${DMENU_EMOJI_RECENT%/*}"

        if "$list"; then
            list
            exit
        fi

        list \
            | ''${DMENU:-dmenu -fn "sans 20px" -l 8 -g 8} -S -i -p "emoji" \
            | while read -r emoji line; do
                "$clip" \
                    && printf '%s' "$emoji" \
                    | xclip -i -selection clipboard \
                    && xclip -o -selection clipboard

                "$type" \
                    && xdotool key "$(printf '%s ' "$emoji")"

                {
                    "$clip" || "$type"
                } || printf '%s\n' "$emoji"

                printf '%s %s\n' "$emoji" "$line" >>"$DMENU_EMOJI_RECENT"
            done

        head -n 64 "$DMENU_EMOJI_RECENT" \
            | uq \
            | sponge "$DMENU_EMOJI_RECENT"
      '';
    });

  dmenu-run = (
    pkgs.writeShellApplication {
      name = "dmenu-run";

      runtimeInputs = [
        dmenu
        pkgs.coreutils
        pkgs.findutils
        pkgs.uq
        pkgs.bfs
        pkgs.gnused
        pkgs.gnugrep
      ];

      text = ''
        h="''${XDG_CACHE_HOME:=$HOME/.cache}"/dmenu/dmenu-run.cache

        mkdir -p "''${h%/*}"

        c=$(
            {
                IFS=:
                # We want the $PATH to be split here.
                # shellcheck disable=SC2086
                find $PATH ! -type d -executable 2>/dev/null \
                    | sed 's@.*/@@' \
                    | sort "$h" - \
                    | cat "$h" - 2>/dev/null
                unset IFS
            }   | uq \
                | ''${DMENU:-dmenu -g 4 -l 16} \
                    -S \
                    -p "run" \
                    "$@"
        )

        [ -n "$c" ] || exit 0

        touch "$h"
        printf '%s\n' "$c" | ''${SHELL:-sh} -x - &
        t=$(mktemp)

        {
            cat - "$h" <<EOF
        $c
        EOF
        }   | head -n 24 \
            | grep -v "^\s*$" \
            | uq \
            | while read -r line; do
                command -v "''${line%% *}" >/dev/null 2>&1
                printf "%s\n" "$line"
            done \
            | sponge "$t"

        mv -f "$t" "$h"
      '';
    });

  dmenu-pass = (
    pkgs.writeShellApplication {
      name = "dmenu-pass";

      runtimeInputs = [
        dmenu
        config.programs.password-store.package
        pkgs.coreutils
        pkgs.findutils
        pkgs.gnugrep
        pkgs.gnused
        pkgs.libnotify
        pkgs.uq
        pkgs.xclip
      ];
      text = ''
        usage() {
            cat >&2 <<EOF
        usage: dmenu-pass [-cn] [-i query] [-m print|username|password|otp] [dmenu options]
        EOF
            exit 69
        }

        : "''${PASSWORD_STORE_DIR:=''${HOME}/.password-store}"
        : "''${PASSWORD_STORE_CLIP_TIME:=45}"
        : "''${XDG_CACHE_HOME:=''${HOME}/.cache}"

        clip=false
        notify=false
        initial=
        mode=password

        while getopts :cni:m: arg >/dev/null 2>&1; do
            case "''${arg}" in
                c) clip=true ;;
                n) notify=true ;;
                i) initial="''${OPTARG}" ;;
                m)
                    case "''${OPTARG}" in
                        print | username | password | otp) mode="''${OPTARG}" ;;
                    esac
                    ;;
                *) usage;;
            esac
        done
        shift $((OPTIND - 1))

        h="''${XDG_CACHE_HOME}"/dmenu/dmenu-pass.cache
        mkdir -p "''${h%/*}"

        c=$(
            (
                cd "''${PASSWORD_STORE_DIR}"
                find .// \
                    -type f \
                    ! -path '*/.*/*' \
                    ! -name '.*' \
                    -name '*.gpg' \
                    -printf '%d %p\n' 2>/dev/null \
                    | sort -n \
                    | sed 's@^[0-9]* @@; s@^\.//@@; s@\.gpg$@@' \
                    | cat "''${h}" - 2>/dev/null
            )   | uq \
                | ''${DMENU:-dmenu} ''${initial:+-n -it "''${initial}"} -S -p "pass"
        )

        [ -n "''${c}" ] || exit 0

        touch "''${h}"

        case "''${mode}" in
            print)
                printf '%s\n' "''${c}"
                ;;
            username)
                username="''${c##*/}"

                if pass show "''${c}" | grep -Eq "^(user|username):"; then
                    username=$(
                        pass show "''${c}" \
                            | sed -E \
                                '/^(user|username):/ s/^(user|username): ?//'
                    )
                fi

                if "''${clip}"; then
                    printf '%s\n' "''${username}" \
                        | xclip -in -selection clipboard
                else
                    printf '%s\n' "''${username}"
                fi
                ;;
            password)
                if "''${clip}"; then
                    out=$(pass show -c "''${c}")
                    if "''${notify}"; then
                        notify-send \
                            -a pass \
                            -i password \
                            "pass" \
                            "Copied $1 to clipboard. Will clear in ''${PASSWORD_STORE_CLIP_TIME} seconds."
                    else
                        printf '%s\n' "''${out}"
                    fi
                else
                    pass show "''${c}" \
                        | head -n1
                fi
                ;;
            otp)
                if "''${clip}"; then
                    out=$(pass otp -c "''${c}")
                    if "''${notify}"; then
                        notify-send \
                            -a pass \
                            -i password \
                            "pass" \
                            "Copied OTP code for $1 to clipboard. Will clear in 45 seconds."
                    else
                        printf '%s\n' "''${out}"
                    fi
                else
                    pass otp "''${c}"
                fi
                ;;
        esac

        t=$(mktemp)

        {
            cat - "''${h}" <<EOF
        $c
        EOF
        }   | head -n 24 \
            | grep -v "^\s*$" \
            | uq \
            | sponge "''${t}"

        mv -f "''${t}" "''${h}"
      '';
    });

  dmenu-session = (
    pkgs.writeShellApplication {
      name = "dmenu-session";

      runtimeInputs = [
        dmenu
        config.xsession.windowManager.bspwm.package
        pkgs.gnugrep
        pkgs.systemd
        pkgs.xorg.xset
      ];

      text = ''
        usage() {
            cat >&2 <<EOF
        usage: ''${0##*/} [dmenu options]
        EOF
            exit 69
        }

        lockScreen=${lib.boolToString config.services.screen-locker.enable}
        lockScreenText=
        screensaverText=
        monitorText=

        if "''${lockScreen}"; then
            lockScreenText="Lock screen"
            screensaverText="Toggle screensaver"
            monitorText="Toggle monitor power saving"
        fi

        choice=$(
            cat <<EOF | ''${DMENU:-dmenu -i} -p "session" "$@"
        Sleep
        Reboot
        $(
            [ -n "''${lockScreen}" ] \
                && printf '%s\n' \
                    "''${lockScreenText}" \
                    "''${screensaverText}" \
                    "''${monitorText}"
        )
        Power off
        Logout
        EOF
        )

        case "''${choice}" in
            "") exit 0 ;;
            "Sleep") systemctl suspend ;;
            "Power off") systemctl poweroff ;;
            "Reboot") systemctl reboot ;;
            "Logout") systemctl --user stop graphical-session.target; bspc quit & ;;
            "''${lockScreenText}") systemctl --user start xsecurelock.service & ;;
            "''${screensaverText}") xsecurelock-toggle & ;;
            "''${monitorText}") dpms-toggle & ;;
            *) usage ;;
        esac
      '';
    });
in
{
  home.persistence."/cache${config.home.homeDirectory}".directories = [ "var/cache/dmenu" ];

  services.sxhkd.keybindings = { "{super + grave, super + Return, alt + F2}" = "dmenu-run"; }
    // lib.optionalAttrs config.xsession.windowManager.bspwm.enable { "super + Escape" = "dmenu-session"; }
    // lib.optionalAttrs (nixosConfig.fonts.fontconfig.defaultFonts.emoji ? null) { "super + e" = "dmenu-emoji -c"; }
    // lib.optionalAttrs config.programs.password-store.enable { "super + shift + p" = "dmenu-pass -cn"; }
  ;

  services.dunst.settings.global.dmenu = "dmenu -p \"notification\"";

  home.packages = [ dmenu dmenu-run ]
    ++ lib.optional config.xsession.windowManager.bspwm.enable dmenu-session
    ++ lib.optional (nixosConfig.fonts.fontconfig.defaultFonts.emoji ? null) dmenu-emoji
    ++ lib.optional config.programs.password-store.enable dmenu-pass
  ;
}

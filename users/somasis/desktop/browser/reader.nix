# Fetch the current page with rdrview(1) and put it in a qutebrowser tab.
{ lib, pkgs, ... }:
let
  hello-css = pkgs.fetchurl {
    url = "https://raw.githubusercontent.com/arp242/hello-css/version-1.5/dist/all.min.css";
    hash = "sha256-me/B8b7fkjtWWEMbIBi0LvT8FCPgsEyt0dKMxA0nxQo=";
  };

  rdrview = pkgs.writeShellScript "rdrview" ''
    set -x

    : "''${QUTE_FIFO:?}"
    : "''${QUTE_URL:?}"
    : "''${QUTE_HTML:?}"

    umask 0077

    PATH=${lib.makeBinPath [ pkgs.rdrview pkgs.coreutils pkgs.gnused ]}:$PATH
    : "''${TMPDIR:=/tmp}"

    exec >> "$QUTE_FIFO"

    case "$QUTE_URL" in
        file://*) QUTE_URL=''${QUTE_URL#file://} ;;
    esac

    tmp=$(mktemp "$TMPDIR"/rdrview.XXXXXXXXX.html)
    base=$(printf '%s\n' "$QUTE_URL" | sed -E '/^[^:]+:\/\/.*\// s|^(.*)/[^/]+$|\1|')

    if ! rdrview -u "$base" -c "$QUTE_HTML"; then
        printf "message-error \"rdrview: could not find article content in '%s'\"\n" "$QUTE_URL"
        cat "$QUTE_HTML" >&2
        exit 1
    fi

    cat >"$tmp" <<EOF
    <!DOCTYPE html>
    <head>
      <meta charset="utf-8">
      <title>rdrview''${QUTE_TITLE:+: $QUTE_TITLE}</title>
      <style>
        $(cat ${hello-css})

        article {
            counter-reset: section;
        }

        article p:before {
            counter-increment: section;
            content: "" counter(section) " ";
            opacity: .5;
            font-weight: bold;
            vertical-align: super;
            font-size: 75%;
        }
      </style>
    </head>
    <body>
    $(
        rdrview ''${QUTE_USER_AGENT:+-A "$QUTE_USER_AGENT"} \
            -T title,byline,body -u "$base" -H "$QUTE_HTML"
    )
    </body>
    EOF

    printf 'open -r %s\n' "$tmp"
  '';
in
{
  programs.qutebrowser = {
    aliases.rdrview = "spawn -u ${rdrview}";
    keyBindings.normal."zpr" = "rdrview";
  };
}

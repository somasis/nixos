# Fetch the current page with rdrview(1) and put it in a qutebrowser tab.
{ lib, pkgs, ... }:
let
  hello-css = pkgs.fetchurl {
    url = "https://raw.githubusercontent.com/arp242/hello-css/version-1.5/dist/all.min.css";
    hash = "sha256-me/B8b7fkjtWWEMbIBi0LvT8FCPgsEyt0dKMxA0nxQo=";
  };

  rdrview = pkgs.writeShellScript "rdrview" ''
    set -eu
    umask 0077

    PATH=${lib.makeBinPath [ pkgs.rdrview pkgs.coreutils pkgs.gnused ]}:$PATH

    : "''${QUTE_FIFO:?}"
    : "''${QUTE_URL:?}"

    exec >> "$QUTE_FIFO"

    rdrview -c "$QUTE_URL"

    : "''${TMPDIR:=/tmp}"
    tmp=$(mktemp "$TMPDIR"/rdrview.XXXXXXXXX.html)
    base=$(printf '%s\n' "$QUTE_URL" | sed -E '/^[^:]+:\/\/.*\// s|^(.*)/[^/]+$|\1|')

    cat >"$tmp" <<EOF
    <!DOCTYPE html>
    <head>
      <meta charset="utf-8">
      <title>rdrview''${QUTE_TITLE:+: $QUTE_TITLE}</title>
      <style>
        $(cat "${hello-css}")
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

    # Remove the temporary files once qutebrowser closes.
    {
      wait $PPID
      rm -f "$tmp"
    } &
  '';
in
{
  programs.qutebrowser.keyBindings.normal."<z><p><r>" = "spawn -u ${rdrview}";
}

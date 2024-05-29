{ lib
, config
, pkgs
, ...
}:
let
  hello-css = pkgs.fetchurl {
    url = "https://raw.githubusercontent.com/arp242/hello-css/version-1.5/dist/all.min.css";
    hash = "sha256-me/B8b7fkjtWWEMbIBi0LvT8FCPgsEyt0dKMxA0nxQo=";
  };

  # Fetch the current page with rdrview(1) and put it in a qutebrowser tab.
  rdrview = pkgs.writeShellScript "rdrview" ''
    : "''${QUTE_FIFO:?}"
    : "''${QUTE_URL:?}"

    if [[ -n "$QUTE_SELECTED_HTML" ]]; then
        html="$QUTE_SELECTED_HTML"
    else
        html=$(<"$QUTE_HTML")
    fi

    umask 0077

    PATH=${lib.makeBinPath [ pkgs.html-tidy pkgs.rdrview pkgs.trurl pkgs.coreutils ]}"''${PATH:+:$PATH}"

    case "$QUTE_URL" in
        file://*) QUTE_URL=''${QUTE_URL#file://} ;;
    esac

    tmp=$(mktemp -t --suffix .html rdrview.XXXXXXXXX)
    base=$(trurl --redirect / -f - <<<"$QUTE_URL")
    html=$(tidy --quiet yes --tidy-mark no --show-body-only yes <<<"$html")

    if ! rdrview -u "$base" -c <<< "$html"; then
        printf "message-error \"rdrview: could not find article content in '%s'\"\n" "$QUTE_URL" > "$QUTE_FIFO"
        exit 1
    fi

    html=$(
        rdrview ''${QUTE_USER_AGENT:+-A "$QUTE_USER_AGENT"} \
            -T title,byline,body -u "$base" -H <<<"$html"
    )

    cat >"$tmp" <<EOF
    <!DOCTYPE html>
    <head>
      <meta charset="utf-8" />
      <title>rdrview''${QUTE_TITLE:+: $QUTE_TITLE}</title>
      <style>
        $(<${hello-css})

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
    $html
    </body>
    EOF

    printf 'open -r %s\n' "$tmp" > "$QUTE_FIFO"
  '';

  print-clean = pkgs.writeShellApplication {
    name = "print-clean";

    runtimeInputs = [
      config.programs.jq.package
      pkgs.coreutils
      pkgs.curl
      pkgs.dateutils
      pkgs.gnugrep
      pkgs.gnused
      pkgs.moreutils
      pkgs.pup
      pkgs.rdrview
      pkgs.runtimeShell
      pkgs.trurl
      pkgs.ugrep
    ];

    text = pkgs.substituteAll {
      src = ./userscripts/print-clean.sh;
      modern-normalize = pkgs.buildNpmPackage rec {
        pname = "modern-normalize";
        version = "2.0.0";

        src = pkgs.fetchFromGitHub {
          owner = "sindresorhus";
          repo = pname;
          rev = "v${version}";
          hash = "sha256-8u3HJ0t6DRR5+vg3/1IezXv9VSmqDCldFN6g+bjVAaY=";
        };

        npmDepsHash = lib.fakeHash;

        meta = with lib; {
          description = "CSS style to normalize browsers' default styles";
          inherit (src.meta) homepage;
          licenses = with licenses; [ mit ];
          maintainers = with maintainers; [ somasis ];
        };
      };
    };
  };

  render = pkgs.writeShellScript "render" ''
    set -euo pipefail

    : "''${QUTE_FIFO:?}"
    : "''${QUTE_URL:?}"
    : "''${QUTE_HTML:?}"
    : "''${QUTE_TEXT:?}"

    umask 0077

    PATH=${lib.makeBinPath [ pkgs.asciidoctor-with-extensions pkgs.pandoc ]}:"$PATH"

    case "$QUTE_URL" in
        file://*)      url=''${QUTE_URL#file://} ;;
        view-source:*) url=''${QUTE_URL#view-source:} ;;
        *)             url="$QUTE_URL" ;;
    esac

    file_type=''${url##*/}
    file_type=''${file_type##*.}

    case "$url" in
        *.txt) file="$QUTE_TEXT" ;;
        *) file="$QUTE_HTML" ;;
    esac

    rendered=$(mktemp --suffix .html)

    case "$file_type" in
        *.md|*.markdown) pandoc -f markdown -t html -o "$rendered" ;;
        *.asciidoc) asciidoctor -o "$rendered" - ;;
        *)
            printf "message-error \"render: unknown file type '%s'\"\n" > "$QUTE_FIFO"
            exit 1
            ;;
    esac

    printf 'open -r %s\n' "$rendered" > "$QUTE_FIFO"
  '';
in
{
  programs.qutebrowser = {
    aliases = {
      rdrview = "spawn -u ${rdrview}";
      render = "spawn -u ${render}";
      # print-clean = "spawn -u ${lib.getExe print-clean}";
    };

    keyBindings.normal = {
      # pp = "print --pdf ${config.xdg.userDirs.download}/{title}.pdf";
      # pP = "print-clean";
      pr = "rdrview";

      zpr = "rdrview";
      zpR = "render";
    };
  };
}

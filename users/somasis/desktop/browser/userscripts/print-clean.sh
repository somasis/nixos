#!@runtimeShell@
# shellcheck shell=bash

set -euo pipefail

PATH=@PATH@

: "${QUTE_FIFO:?}"
: "${QUTE_USER_AGENT:?}"
: "${QUTE_URL:=${1:?no URL provided and QUTE_URL is not set}}"

article_out=$(mktemp --suffix=".html")

include_title=true
include_byline=true
include_excerpt=true
include_body=true
include_date=true
include_sitename=true

if [[ -v QUTE_HTML ]]; then
    article_html="${QUTE_HTML}"
else
    article_html=$(curl -Lfs -A "${QUTE_USER_AGENT}" "${QUTE_URL}")
fi

article_baseurl=$(trurl -s path= "${QUTE_URL}")
article_metadata=$(rdrview -u "${article_baseurl}" -M <<<"${article_html}")

article_title=$(grep '^Title: ' <<<"${article_metadata}")
article_title=${article_title#Title: }

article_byline=$(grep '^Byline: ' <<<"${article_metadata}")
article_byline=${article_byline#Byline: }

article_sitename=$(grep '^Site name: ' <<<"${article_metadata}")
article_sitename=${article_sitename#Site name: }

article_excerpt=$(grep '^Excerpt: ' <<<"${article_metadata}")
article_excerpt=${article_excerpt#Excerpt: }

article_date=$(
    pup \
        '[property="article:published_time"], [itemprop="datePublished"] attr{content}' \
        <<<"${article_html}" \
        | head -n1
)

if [[ -z "${article_date}" ]]; then
    article_date=$(pup -p 'script[type^="application/"][type*="json"] text{}' <<<"${article_html}")
    if jq -e '."@context" == "https://schema.org"' <<<"${article_date}" >/dev/null 2>&1; then
        article_date=$(
            jq -r '
                ."@graph"
                    | map(
                        select(
                            has("datePublished")
                                or has("dateModified")
                        )
                        | (.datePublished // .dateModified)
                    )
                    | sort
                    | first
            ' <<<"${article_date}"
        )
    fi
fi

[[ -n "${article_date}" ]] && article_date_pretty=$(dateconv -f '%Y-%m-%d' "${article_date}") || include_date=

article_body_first_paragraph=$(
    rdrview -u "${article_baseurl}" -H -T body <<<"${article_html}" \
        | pup 'body text{}' \
        | grep -v '^\s*$' \
        | head -n1
)

article_sitename_escaped=$(sed 's/[][\.|$(){}?+*^]/\\&/g' <<<"${article_sitename}")
if article_title_stem=$(
    ugrep \
        -o \
        -Z \
        -e "[[:blank:]]+[[:punct:]]+[[:blank:]]+${article_sitename_escaped}$" \
        -e "${article_sitename_escaped}[[:blank:]]+[[:punct:]]+[[:blank:]]+" \
        -e "${article_sitename_escaped}[[:punct:]]+[[:blank:]]+" \
        <<<"${article_title}"
); then
    article_title=${article_title/"${article_title_stem}"/}
    :
fi

article_excerpt=$(
    sed -E \
        -e 's/\.{3}$|…$//' \
        -e 's/^\s*|\s*$//' \
        <<<"${article_excerpt}"
)

if ugrep -qZ -F "${article_excerpt}" <<<"${article_body_first_paragraph}"; then
    include_excerpt=
fi

article_body=$(rdrview -u "${article_baseurl}" -H <<<"${article_html}")

#         <link rel="stylesheet" href="https://unpkg.com/gutenberg-css@0.7" media="print" />
#         <link rel="stylesheet" href="https://unpkg.com/gutenberg-css@0.7/dist/themes/oldstyle.min.css" media="print" />
cat >"${article_out}" <<EOF
<!DOCTYPE html>
<html>
    <head>
        <meta charset="utf-8" />
        ${include_title:+"<title>${article_title}</title>"}
        ${include_excerpt:+"<meta name=\"description\" content=\"${article_excerpt}\" />"}
        ${include_byline:+"<meta name=\"author\" content=\"${article_byline}\" />"}
        ${include_date:+"<meta name=\"date\" content=\"${article_date}\" />"}
        ${include_sitename:+"<meta name=\"publisher\" content=\"${article_sitename}\" />"}

        <style>$(<@modern-normalize@)</style>
        <style>
            @media screen {
                body {
                    margin: 2em auto;
                    width: calc(100% - 2in);
                    max-width: 8.5in;
                }
            }

            html {
                font-family: serif;
                line-height: 1.5;
            }

            h1 { font-size: 2.00em; }
            h2 { font-size: 1.50em; }
            h3 { font-size: 1.17em; }
            h4 { font-size: 1.00em; }
            h5 { font-size: 0.83em; }
            h6 { font-size: 0.67em; }

            small { font-size: 90%; }

            body > article > div#body p {
                text-align: justify;
                text-indent: .5in;
                margin: 0;
            }

            body > article > div#body p:has(strong:only-child) {
                text-indent: initial;
                padding-top: 1lh;
            }

            body > article > header {
                margin-bottom: 1lh;
            }

            body > article > header > h1 {
                font-weight: bold;
                text-align: left;
            }

            body > article > header > small[itemprop="description"] {
                display: block;

                font-style: italic;
                text-align: justify;
                margin-top: 1lh;
                margin-bottom: 1lh;
            }

            body > article > footer {
                margin-top: 1lh;
                font-style: italic;
                text-align: right;
            }

            body > article > footer > address[rel="author"] {
                font-style: italic;
                text-align: right;
            }

            @page {
                margin: 1in;
                size: letter portrait;
            }

            @page:left {
                @top-left {
                    content: counter(page);
                }
            }

            @page:right {
                @top-right {
                    content: counter(page);
                }
            }

            @media print {
                body > article > div#body blockquote,
                body > article > div#body ul,
                body > article > div#body ol,
                body > article > div#body li {
                    page-break-inside: auto;
                }

                body > article > div#body table,
                body > article > div#body figure {
                    page-break-inside: avoid;
                }

                body > article > header > h1,
                body > article > header > h2,
                body > article > header > h3,
                body > article > header > h4,
                body > article > header > h5 {
                    page-break-after: avoid;
                }

                p {
                    orphans: 2;
                    widows: 2;
                }
            }
        </style>
    </head>
    <body>
        <article itemscope itemtype="http://schema.org/Article">
            <header>
                ${include_title:+"<h1 itemprop=\"name\">${article_title}</h1>"}
                ${include_excerpt:+"<small itemprop=\"description\">${article_excerpt}</small>"}
            </header>
            <div id="body" itemprop="articleBody">${article_body}</div>
            <footer>
                ${include_byline:+"<address rel=\"author\" itemprop=\"author\">${article_byline}</address>"}
                ${include_date:+"<time itemprop=\"datePublished\" datetime=\"${article_date}\">${article_date_pretty}</time>"}
                ${include_sitename:+"<address itemprop=\"publication\">${article_sitename}</address>"}
            </footer>
        </article>
    </body>
</html>
EOF

printf 'open -rt %s\n' >>"${QUTE_FIFO}"

# nohup chromium "${articles[@]}" >/dev/null 2>&1
(
    sleep 60
    rm -f "${article_out}"
) &
#     disown

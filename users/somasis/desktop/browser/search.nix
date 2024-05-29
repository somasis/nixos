{ config
, lib
, pkgs
, ...
}:
let
  inherit (lib)
    makeBinPath
    mapAttrs'
    nameValuePair
    replaceStrings
    ;

  memento = pkgs.writeShellScript "qutebrowser-memento" ''
    export PATH=${makeBinPath [ pkgs.coreutils pkgs.dateutils ] }

    usage() {
        cat <<EOF >&2
    usage: QUTE_FIFO=... qutebrowser-memento [date [URL]]
    EOF
        exit 69
    }

    [[ $# -le 2 ]] || usage

    : "''${QUTE_FIFO:?}"
    exec > "$QUTE_FIFO"

    timetravel="https://timetravel.mementoweb.org/memento"
    date=$(dateconv -z UTC -f "%Y%m%d%H%M%S" "''${1:-now}")

    printf 'open -r %s/%s/%s\n' \
        "$timetravel" \
        "$date" \
        "''${QUTE_URL:-$2}"
  '';

  wayback = pkgs.writeShellScript "wayback" ''
    PATH=${lib.makeBinPath [ pkgs.curl pkgs.jq pkgs.savepagenow ]}:"$PATH"

    : "''${QUTE_FIFO:?}"
    : "''${QUTE_TAB_INDEX:?}"

    url="''${QUTE_URL:-''${1?error: no URL provided}}"

    wayback_response=
    wayback_archived_url=

    check_wayback() {
        wayback_response=$(
            curl -f -s -G --url-query "url=$url" "https://archive.org/wayback/available"
        )

        wayback_archived_url=$(
            <<<"$wayback_response" jq -er '
                if .archived_snapshots == {} then
                    ""
                else
                    .archived_snapshots.closest.url
                end
            '
        )
    }

    check_wayback
    # printf 'message-info "wayback: checking if URL archived..."\n' > "$QUTE_FIFO"

    if [ -n "$wayback_archived_url" ]; then
        printf 'message-info "wayback: has URL, redirecting."\n' > "$QUTE_FIFO"
        printf 'cmd-run-with-count %s open -r %s\n' "$QUTE_TAB_INDEX" "$wayback_archived_url" > "$QUTE_FIFO"
    else
        printf 'message-info "wayback: does not have URL, archiving \"%s\"..."' "$url" > "$QUTE_FIFO"
        if wayback_archived_url=$(savepagenow -c "$url"); then
            printf 'message-info "wayback: archived URL, redirecting..."\n' > "$QUTE_FIFO"
            printf 'cmd-run-with-count %s open -r %s\n' "$QUTE_TAB_INDEX" "$wayback_archived_url" > "$QUTE_FIFO"
        else
            printf 'message-error "wayback: failed to archive URL"\n' > "$QUTE_FIFO"
            exit 1
        fi
    fi
  '';

  wikipedia = lang: "https://${lang}.wikipedia.org/w/index.php?search={}";
in
{
  programs.qutebrowser = rec {
    searchEngines = {
      "DEFAULT" = "https://html.duckduckgo.com/html/?q={}";
      "!" = "https://duckduckgo.com/?q=!+{}";
      "!i" = "https://duckduckgo.com/?q={}&ia=images&iax=images";

      "!g" = "https://google.com/search?udm=14&q={}";
      "!gi" = "https://google.com/search?tbm=isch&source=hp&q={}";
      "!yt" = "https://www.youtube.com/results?search_query={}";

      "!appstate" = "https://gb1.appstate.edu/search?q={}";
      # "!apppeople" = "https://search.appstate.edu/search.php?last={}&type=all";
      # "!atsd" = "https://jira.appstate.edu/browse/ATSD-{}";
      # "!tss" = "https://jira.appstate.edu/secure/QuickSearch.jspa?searchString={}";
      # "!dell" = "https://www.dell.com/support/home/en-us/product-support/servicetag/{}";

      "!libgen" = "http://libgen.rs/index.php?req={}";
      "!anna" = "https://annas-archive.org/search?q={}";
      "!annapdf" = searchEngines."!anna" + "&ext=pdf";
      "!worldcat" = "https://www.worldcat.org/search?q={}";

      "!bookfinder" = "https://www.bookfinder.com/search/?keywords={}";
      "!abebooks" = "https://www.abebooks.com/servlet/SearchResults?kn={}";
      "!plato" = "https://plato.stanford.edu/search/searcher.py?query={}";
      "!iep" = replaceStrings [ "{}" ] [ "site:https://iep.utm.edu+{}" ] searchEngines.DEFAULT;
      "!doi" = "https://doi.org/{unquoted}";

      "!pkg" = "https://parcelsapp.com/en/tracking/{}";

      "!discogs" = "https://www.discogs.com/search/?q={}";

      "!mbartist" = "https://musicbrainz.org/search?query={}&type=artist";
      "!mbrecording" = "https://musicbrainz.org/search?query={}&type=recording";
      "!mbrelease" = "https://musicbrainz.org/search?query={}&type=release";
      "!mbreleasegroup" = "https://musicbrainz.org/search?query={}&type=release_group";
      "!mbseries" = "https://musicbrainz.org/search?query={}&type=series";
      "!mbwork" = "https://musicbrainz.org/search?query={}&type=work";

      "!imdb" = "https://www.imdb.com/find/?s=all&q={}";
      "!ltrbox" = "https://letterboxd.com/search/{}/";
      "!trakt" = "https://trakt.tv/search?query={}";

      "!osm" = "https://www.openstreetmap.org/search?query={}";
      "!osmwiki" = "https://wiki.openstreetmap.org/wiki/Special:Search?search={}&go=Go";
      "!gmaps" = "https://www.google.com/maps/search/{}";
      "!flight" = "https://flightaware.com/ajax/ignoreall/omnisearch/disambiguation.rvt?searchterm={}&token=";

      "!red" = "https://redacted.ch/torrents.php?searchstr={}";
      "!redartist" = "https://redacted.ch/artist.php?artistname={}";
      "!redforums" = "https://redacted.ch/forums.php?action=search&search={}";
      "!redlog" = "https://redacted.ch/log.php?search={}";
      "!redrequests" = "https://redacted.ch/requests.php?search={}";
      "!redusers" = "https://redacted.ch/user.php?action=search&search={}";
      "!rutracker" = "https://rutracker.org/forum/tracker.php?nm={}";
      "!nyaa" = "https://nyaa.si/?q={}";

      "!gh" = "https://github.com/search?q={}";

      "!nix" = "file://${config.nix.package.doc}/share/doc/nix/manual/index.html?search={}";
      "!nixdiscuss" = "https://discourse.nixos.org/search?q={}";
      "!nixpkgsissues" = "https://github.com/NixOS/nixpkgs/issues?q={}";
      "!nixopts" = "https://search.nixos.org/options?channel=unstable&sort=alpha_asc&query={}";
      "!nixpkgs" = "https://search.nixos.org/packages?channel=unstable&sort=alpha_asc&query={}";
      "!nixwiki" = "https://nixos.wiki/index.php?go=Go&search={}";
      "!hmissues" = "https://github.com/nix-community/home-manager/issues?q={}";

      "!mdn" = "https://developer.mozilla.org/en-US/search?q={}";
      "!c" = replaceStrings [ "{}" ] [ "site:en.cppreference.com/w/c+{}" ] searchEngines.DEFAULT;

      "!greasyfork" = "https://greasyfork.org/en/scripts?q={}";
      "!openuserjs" = "https://openuserjs.org/?q={}";
      "!userstyles" = "https://userstyles.world/search?q={}";

      "!twitter" = "https://twitter.com/search?q={}";
      "!whosampled" = "https://www.whosampled.com/search/?q={}";

      "!wiki" = wikipedia "en";
      "!wiki#en" = wikipedia "en";
      "!wiki#es" = wikipedia "es";
      "!wiki#jp" = wikipedia "ja";
      "!wiki#tok" = "https://wikipesija.org/index.php?search={}";

      "!etym" = "https://www.etymonline.com/search?q={}";
      "!wikt" = "https://en.wiktionary.org/wiki/{}";
      "!en" = "${searchEngines."!wikt"}#English";
      "!es" = "${searchEngines."!wikt"}#Spanish";
      "!jp" = "${searchEngines."!wikt"}#Japanese";
      "!tok" = "https://wikipesija.org/wiki/nimi:{unquoted}";
      "!esen" = "https://www.wordreference.com/es/en/translation.asp?spen={}";
      "!enes" = "https://www.wordreference.com/es/translation.asp?tranword={}";
      "!linku" = "https://linku.la/?q={}";

      "!archman" = "https://man.archlinux.org/search?q={}";
      "!archpkgs" = "https://archlinux.org/packages/?sort=&q={}";
      "!archwiki" = "https://wiki.archlinux.org/index.php?title=Special%3ASearch&search={}";

      "!debman" = "https://manpages.debian.org/jump?q={}";
      "!debpkgs" = "https://packages.debian.org/search?keywords={}";

      "!repology" = "https://repology.org/projects/?search={}";

      "!ia" = "https://archive.org/search?query={}";
      "!a" = "https://web.archive.org/web/*/{unquoted}";
      "!A" = "https://archive.today/{unquoted}";

      "!adb" = "http://adb.arcadeitalia.net/dettaglio_mame.php?game_name={}&arcade_only=0&autosearch=1";
      "!cdromance" = "https://cdromance.com/?s={}";
      "!emugen" = "https://emulation.gametechwiki.com/index.php?title=Special%3ASearch&search={}";
      "!redump" = "http://redump.org/discs/quicksearch/{quoted}";
      "!vimm" = "https://vimm.net/vault/?p=list&q={}";

      "!gemini" = "https://portal.mozz.us/gemini/{unquoted}";

      "!phish" = "https://phish.in/{unquoted}";
      "!phishin" = "https://phish.net/setlists/?d={}";
    };

    aliases =
      let
        search-with-selection = pkgs.writeShellScript "search-with-selection" ''
          PATH=${lib.makeBinPath [ pkgs.s6-portable-utils ]}:"$PATH"
          : "''${QUTE_FIFO:?}"
          : "''${QUTE_SELECTED_TEXT:?}"

          args=( "$@" "$QUTE_SELECTED_TEXT" )
          i=0
          until [[ "$i" -gt "''${#args[@]}" ]]; do
              args[$i]=( "$(s6-quote -d '"' "\"''${args[$i]}")\"" )
              i=$(( i + 1 ))
          done
          printf 'open -rt %s\n' "''${args[*]}" > "$QUTE_FIFO"
        '';
      in
      {
        memento = "spawn -u ${memento}";
        search-with-selection = "spawn -u ${search-with-selection}";
        wayback = "spawn -u ${wayback}";
      };

    keyBindings.normal = {
      gsw = "search-with-selection !wikt";
    }
    // (
      let
        open = x: "open -r ${x}";
        openNewTab = x: "open -rt ${x}";
      in
      mapAttrs' (n: v: nameValuePair "r${n}" v) {
        # "1" = open "https://12ft.io/api/proxy?q={url}";
        # "a" = open "https://web.archive.org/web/*/{url}";
        "a" = "wayback {url}";
        "A" = open "https://archive.today/newest/{url}";
        "m" = "memento";
        "M" = "memento now";
      }
    );

    greasemonkey = map config.lib.somasis.drvOrPath [
      # Google
      (pkgs.fetchurl { hash = "sha256-azHAQKmNxAcnyc7l08oW9X6DuMqAblFGPwD8T9DsrSs="; url = "https://greasyfork.org/scripts/32635-disable-google-search-result-url-redirector/code/Disable%20Google%20Search%20Result%20URL%20Redirector.user.js"; })
      (pkgs.fetchurl { hash = "sha256-Bb1QsU6R9xU718hRskGbuwNO7rrhuV7S1gvKtC9SlL0="; url = "https://greasyfork.org/scripts/37166-add-site-search-links-to-google-search-result/code/Add%20Site%20Search%20Links%20To%20Google%20Search%20Result.user.js"; })
      (pkgs.fetchurl { hash = "sha256-r4UF6jr3jhVP7JxJNPBzEpK1fkx5t97YWPwf37XLHHE="; url = "https://greasyfork.org/scripts/383166-google-images-search-by-paste/code/Google%20Images%20-%20search%20by%20paste.user.js"; })
      (pkgs.fetchurl { hash = "sha256-O3u5XsGhgv63f49PwHaybekGjL718Biucb0T6wGGws8="; url = "https://gist.githubusercontent.com/bijij/58cc8cfc859331e4cf80210528a7b255/raw/viewimage.user.js"; })
      (pkgs.fetchurl { hash = "sha256-O+CuezLYKcK2Qh4jq4XxrtEEIPKOaruHnUGQNwkkCF8="; url = "https://greasyfork.org/scripts/381497-reddit-search-on-google/code/Reddit%20search%20on%20Google.user.js"; })
      (pkgs.fetchurl { hash = "sha256-WCgJGlz+FOPCSo+dPDxXB6mdzXBa81mlZ7km+11dBhY="; url = "https://update.greasyfork.org/scripts/495275/Open%20Google%27s%20New%20%22Web%22%20Search%20by%20Default.user.js"; })
    ];
  };
}

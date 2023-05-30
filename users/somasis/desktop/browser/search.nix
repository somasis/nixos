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
in
{
  programs.qutebrowser = rec {
    searchEngines = {
      "DEFAULT" = "https://html.duckduckgo.com/html/?q={}";
      "!" = "https://duckduckgo.com/?q=!+{}";
      "!i" = "https://duckduckgo.com/?q={}&ia=images&iax=images";

      "!g" = "https://google.com/search?q={}";
      "!gi" = "https://google.com/search?tbm=isch&source=hp&q={}";
      "!yt" = "https://www.youtube.com/results?search_query={}";

      "!appstate" = "https://gb1.appstate.edu/search?q={}";
      "!apppeople" = "https://search.appstate.edu/search.php?last={}&type=all";
      "!atsd" = "https://jira.appstate.edu/browse/ATSD-{}";
      "!tss" = "https://jira.appstate.edu/secure/QuickSearch.jspa?searchString={}";
      "!dell" = "https://www.dell.com/support/home/en-us/product-support/servicetag/{}";

      "!libgen" = "http://libgen.rs/index.php?req={}";
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

      "!letterboxd" = "https://letterboxd.com/search/{}/";
      "!imdb" = "https://www.imdb.com/find/?s=all&q={}";

      "!osm" = "https://www.openstreetmap.org/search?query={}";
      "!osmwiki" = "https://wiki.openstreetmap.org/wiki/Special:Search?search={}&go=Go";
      "!gmaps" = "https://www.google.com/maps/search/{}";
      "!fa" = "https://flightaware.com/ajax/ignoreall/omnisearch/disambiguation.rvt?searchterm={}&token=";

      "!red" = "https://redacted.ch/torrents.php?searchstr={}";
      "!redartist" = "https://redacted.ch/artist.php?artistname={}";
      "!redforums" = "https://redacted.ch/forums.php?action=search&search={}";
      "!redlog" = "https://redacted.ch/log.php?search={}";
      "!redrequests" = "https://redacted.ch/requests.php?search={}";
      "!redusers" = "https://redacted.ch/user.php?action=search&search={}";
      "!rutracker" = "https://rutracker.org/forum/tracker.php?nm={}";

      "!gh" = "https://github.com/search?q={}";

      "!nix" = "file://${config.nix.package.doc}/share/doc/nix/manual/index.html?search={}";
      "!nixdiscuss" = "https://discourse.nixos.org/search?q={}";
      "!nixissues" = "https://github.com/NixOS/nixpkgs/issues?q={}";
      "!nixopts" = "https://search.nixos.org/options?channel=unstable&sort=alpha_asc&query={}";
      "!nixpkgs" = "https://search.nixos.org/packages?channel=unstable&sort=alpha_asc&query={}";
      "!nixwiki" = "https://nixos.wiki/index.php?go=Go&search={}";

      "!mdn" = "https://developer.mozilla.org/en-US/search?q={}";

      "!greasyfork" = "https://greasyfork.org/en/scripts?q={}";
      "!openuserjs" = "https://openuserjs.org/?q={}";
      "!userstyles" = "https://userstyles.world/search?q={}";

      "!twitter" = "https://twitter.com/search?q={}";
      "!whosampled" = "https://www.whosampled.com/search/?q={}";

      "!wiki" = "https://www.wikipedia.org/search-redirect.php?family=wikipedia&go=Go&search={}";
      "!wiki#en" = "https://www.wikipedia.org/search-redirect.php?family=wikipedia&language=en&go=Go&search={}";
      "!wiki#es" = "https://www.wikipedia.org/search-redirect.php?family=wikipedia&language=es&go=Go&search={}";
      "!wiki#tok" = "https://wikipesija.org/index.php?go=o+tawa&search={}";

      "!wikt" = "https://en.wiktionary.org/wiki/{}";
      "!en" = "${searchEngines."!wikt"}#English";
      "!es" = "${searchEngines."!wikt"}#Spanish";
      "!esen" = "https://www.wordreference.com/es/en/translation.asp?spen={}";
      "!enes" = "https://www.wordreference.com/es/translation.asp?tranword={}";

      "!tok" = "https://wikipesija.org/wiki/nimi:{}";
      "!linku" = "https://lipu-linku.github.io/?q={}";

      "!archman" = "https://man.archlinux.org/search?q={}";
      "!archpkgs" = "https://archlinux.org/packages/?sort=&q={}";
      "!archwiki" = "https://wiki.archlinux.org/index.php?title=Special%3ASearch&search={}";

      "!ia" = "https://archive.org/search?query={}";
      "!a" = "https://web.archive.org/web/*/{unquoted}";
      "!A" = "https://archive.today/web/*/{unquoted}";

      "!adb" = "http://adb.arcadeitalia.net/dettaglio_mame.php?game_name={}&arcade_only=0&autosearch=1";
      "!cdromance" = "https://cdromance.com/?s={}";
      "!emugen" = "https://emulation.gametechwiki.com/index.php?title=Special%3ASearch&search={}";
      "!redump" = "http://redump.org/discs/quicksearch/{quoted}";
      "!vimm" = "https://vimm.net/vault/?p=list&q={}";
    };

    aliases =
      let
        searchWithSelection = pkgs.writeShellScript "search-with-selection" ''
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
        search-with-selection = "spawn -u ${searchWithSelection}";
      };

    keyBindings.normal = { "gsw" = "search-with-selection !wikt"; }
      // (
      let
        open = x: "open -r ${x}";
        openNewTab = x: "open -rt ${x}";
      in
      mapAttrs' (n: v: nameValuePair "r${n}" v) {
        "1" = open "https://12ft.io/api/proxy?q={url}";
        "a" = open "https://web.archive.org/web/id_/{url}";
        "A" = open "https://archive.is/{url}";
        "m" = "memento";
        "M" = "memento now";
      }
    );
  };
}

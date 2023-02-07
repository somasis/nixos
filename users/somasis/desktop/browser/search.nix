{ config
, lib
, ...
}: {
  programs.qutebrowser.searchEngines = rec {
    "DEFAULT" = "https://duckduckgo.com/?q={}";
    "!" = "https://duckduckgo.com/?q=!+{}";
    "!i" = "https://duckduckgo.com/?q={}&ia=images&iax=images";

    "!g" = "https://google.com/search?q={}";
    "!gi" = "https://google.com/search?tbm=isch&source=hp&q={}";
    "!yt" = "https://www.youtube.com/results?search_query={}";

    "!libgen" = "http://libgen.rs/index.php?req={}";
    "!bookfinder" = "https://www.bookfinder.com/search/?keywords={}";
    "!abebooks" = "https://www.abebooks.com/servlet/SearchResults?kn={}";

    "!appstate" = "https://gb1.appstate.edu/search?q={}";
    "!apppeople" = "https://search.appstate.edu/search.php?last={}&type=all";
    "!library" = "https://login.proxy006.nclive.org/login?qurl=http%3A%2F%2Fsearch.ebscohost.com%2Flogin.aspx%3Fdirect%3Dtrue%26site%3Deds-live%26scope%3Dsite%26group%3Dmain%26profile%3Deds%26authtime%3Dcookie%2Cip%2Cuid%26bQuery%3D{quoted}";
    "!scholar" = "https://login.proxy006.nclive.org/login?qurl=https%3A%2F%2Fscholar.google.com%2Fscholar%3Fhl%3Den%26q%3D{quoted}%26btnG%3DSearch";

    "!pkg" = "https://parcelsapp.com/en/tracking/{}";

    "!discogs" = "https://www.discogs.com/search/?q={}";

    "!mbartist" = "https://musicbrainz.org/search?query={}&type=artist&method=advanced";
    "!mbrecording" = "https://musicbrainz.org/search?query={}&type=recording&method=advanced";
    "!mbrelease" = "https://musicbrainz.org/search?query={}&type=release&method=advanced";
    "!mbreleasegroup" = "https://musicbrainz.org/search?query={}&type=release_group&method=advanced";
    "!mbwork" = "https://musicbrainz.org/search?query={}&type=work&method=advanced";

    "!osm" = "https://www.openstreetmap.org/search?query={}";
    "!osmwiki" = "https://wiki.openstreetmap.org/wiki/Special:Search?search={}&go=Go";
    "!gmaps" = "https://www.google.com/maps/search/{}";

    "!red" = "https://redacted.ch/torrents.php?searchstr={}";
    "!redartist" = "https://redacted.ch/artist.php?artistname={}";
    "!redforums" = "https://redacted.ch/forums.php?action=search&search={}";
    "!redlog" = "https://redacted.ch/log.php?search={}";
    "!redrequests" = "https://redacted.ch/requests.php?search={}";
    "!redusers" = "https://redacted.ch/user.php?action=search&search={}";

    "!gh" = "https://github.com/search?q={}";

    "!nix" = "file://${config.nix.package.doc}/share/doc/nix/manual/index.html?search={}";
    "!nixissues" = "https://github.com/NixOS/nixpkgs/issues?q={}";
    "!nixopts" = "https://search.nixos.org/options?channel=unstable&sort=alpha_asc&query={}";
    "!nixpkgs" = "https://search.nixos.org/packages?channel=unstable&sort=alpha_asc&query={}";
    "!nixwiki" = "https://nixos.wiki/index.php?go=Go&search={}";

    "!mdn" = "https://developer.mozilla.org/en-US/search?q={}";

    "!greasyfork" = "https://greasyfork.org/en/scripts?q={}";
    "!openuserjs" = "https://openuserjs.org/?q={}";

    "!twitter" = "https://twitter.com/search?q={}";
    "!whosampled" = "https://www.whosampled.com/search/?q={}";

    "!wiki" = "https://www.wikipedia.org/search-redirect.php?family=wikipedia&go=Go&search={}";
    "!wiki#en" = "https://www.wikipedia.org/search-redirect.php?family=wikipedia&language=en&go=Go&search={}";
    "!wiki#es" = "https://www.wikipedia.org/search-redirect.php?family=wikipedia&language=es&go=Go&search={}";
    "!wiki#tok" = "https://wikipesija.org/index.php?go=o+tawa&search={}";

    "!en" = "https://en.wiktionary.org/wiki/{}#English";
    "!es" = "https://en.wiktionary.org/wiki/{}#Spanish";
    "!tok" = "https://wikipesija.org/wiki/nimi:{}";
    "!linku" = "https://lipu-linku.github.io/?q={}";

    "!plato" = "https://plato.stanford.edu/search/searcher.py?query={}";
    "!iep" = lib.replaceStrings [ "{}" ] [ "site:https://iep.utm.edu+{}" ] DEFAULT;

    "!archman" = "https://man.archlinux.org/search?q={}";
    "!archpkgs" = "https://archlinux.org/packages/?sort=&q={}";
    "!archwiki" = "https://wiki.archlinux.org/index.php?title=Special%3ASearch&search={}";

    "!archive" = "https://archive.ph/{unquoted}";
    "!wayback" = "https://web.archive.org/web/*/{unquoted}";

    "!adb" = "http://adb.arcadeitalia.net/dettaglio_mame.php?game_name={}&arcade_only=0&autosearch=1";
    "!cdromance" = "https://cdromance.com/?s={}";
    "!emugen" = "https://emulation.gametechwiki.com/index.php?title=Special%3ASearch&search={}";
    "!redump" = "http://redump.org/discs/quicksearch/{quoted}";
    "!vimm" = "https://vimm.net/vault/?p=list&q={}";

    "!atsd" = "https://jira.appstate.edu/browse/ATSD-{}";
    "!tss" = "https://jira.appstate.edu/secure/QuickSearch.jspa?searchString={}";
    "!dell" = "https://www.dell.com/support/home/en-us/product-support/servicetag/{}";
  };
}

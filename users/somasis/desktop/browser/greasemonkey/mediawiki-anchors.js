// ==UserScript==
// @name         MediaWiki Anchor links
// @version      0.1-somasis
// @namespace    https://github.com/OoDeLally/wikipedia-anchors
// @description  Add an anchored link to titles on Wikipedia/Wikipesija articles
// @author       Pascal Heitz (original author)
// @author       Kylie McClain <kylie@somas.is> (modifications)
// @license      MIT
// @match        http://wikipedia.org/*
// @match        https://wikipedia.org/*
// @match        http://*.wikipedia.org/*
// @match        https://*.wikipedia.org/*
// @match        http://wikipesija.org/*
// @match        https://wikipesija.org/*
// @match        http://*.wikipesija.org/*
// @match        https://*.wikipesija.org/*
// @match        http://wiktionary.org/*
// @match        https://wiktionary.org/*
// @match        http://*.wiktionary.org/*
// @match        https://*.wiktionary.org/*
// @grant        GM_addStyle
// ==/UserScript==
//
// NOTE(somasis): Modified slightly from <https://github.com/OoDeLally/wikipedia-anchors>.
//                `@match` rules now have Wikipesija and Wiktionary support.
//                Anchor links are now prepended to the headers, and with link icons
//                rather than "[ link ]" text.

function createDivider() {
    var divider = document.createElement("span");
    divider.innerHTML = " | ";
    divider.classList.add("mw-editsection-divider");
    divider.style.display = "inline";
    return divider;
}

function createLink(href) {
    var link = document.createElement("a");
    link.classList.add("somasis-anchor");
    link.innerHTML = "&#x1F517;&#xFE0E;&nbsp;";
    link.href = href;
    return link;
}

(function() {
    "use strict";

    GM_addStyle(`
        .somasis-anchor {
            display: inline;
            filter: grayscale(100%) sepia(500%) contrast(500%) brightness(0%);
            font-size: .65em;
            user-select: none;
            vertical-align: middle;
        }

        .somasis-anchor:hover, .somasis-anchor:focus { text-decoration: none; }
    `);

    var headers = document.querySelectorAll("h1, h2, h3, h4, h5, h6");
    for (var header of headers) {
        var headlineSpan = header.querySelectorAll("span.mw-headline")[0];
        if (!headlineSpan) {
            continue;
        }

        var headlineId = headlineSpan.id;
        if (!headlineId) {
            continue;
        }

        var anchoredLink = createLink(document.location.href.match(/(^[^#]*)/)[0] + "#" + headlineId);
        var editsectionSpan = header.querySelectorAll("span.mw-editsection")[0];
        headlineSpan.prepend(anchoredLink);
    }
})();

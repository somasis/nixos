// ==UserScript==
// @name            Rewrite and proxy smolweb links
// @description     Rewrites smolweb (gemini, gopher, etc.) links to use a *->HTTP proxy.
// @version         0.1
// @author          Kylie McClain <kylie@somas.is>
// @namespace       https://somas.is
// @license         CC0-1.0
// @include         *://*/*
// @grant           none
// ==/UserScript==

(function() {
'use strict';

const protocols = [
    // { protocol: "gopher:", proxy: "https://gopher.floodgap.com/gopher.lite/gw?a={host}{path_without_host}" },
    { protocol: "gemini:", proxy: new URL("https://portal.mozz.us/gemini") }
];

var pageLinks = document.getElementsByTagName("a");
var pageLinksArray = Array.from(pageLinks);

for (const protocol of protocols) {
    var protocolLinks = [];

    for (var i = 0, imax = pageLinksArray.length; i < imax; i++) {
        if (pageLinks.item(i).protocol == protocol.protocol) { protocolLinks.push(i); }
    }

    if (protocolLinks.length == 0) { continue; }

    for (const linkNum of protocolLinks) {
        var before = pageLinks.item(linkNum);
        var after = new URL(before);

        after.protocol = protocol.proxy.protocol;
        after.host = protocol.proxy.host;
        after.pathname = `${protocol.proxy.pathname}${before.host}${before.pathname}`;

        before.href = after.href;
        console.log(`${protocol.protocol}: rewrote '${before.href}' -> '${after.href}'`);
    }
}
})();


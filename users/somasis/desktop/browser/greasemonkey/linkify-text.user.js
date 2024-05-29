// ==UserScript==
// @name          Linkify Text
// @description   Make URLs in plain text into hyperlinks (using Linkify Plus Plus Core)
// @author        Kylie McClain <kylie@somas.is>
// @namespace     https://somas.is
// @license       CC0-1.0
// @include       *://*/*
// @require       https://unpkg.com/linkify-plus-plus-core@0.6.1/dist/linkify-plus-plus-core.min.js
// @run-at        document-end
// ==/UserScript==

const { UrlMatcher, Linkifier } = linkifyPlusPlusCore;

(function () {
    "use strict";

    // Use defaults from <https://github.com/eight04/linkify-plus-plus/blob/v11.0.0/src/lib/pref-default.js>.
    const matcher = new UrlMatcher({
        boundaryLeft: "{[(\"'<",
        boundaryRight: ">'\")]},.;?!",
    });

    const linkifier = new Linkifier(document.body, {
        matcher: matcher,

        // Don't embed image URLs
        embedImage: false,
    });

    linkifier.on("complete", (elapse) => {
        console.info("linkify-text: finished in %fms", elapse);
    });
    linkifier.on("error", (err) => {
        console.error("linkify-text: failed with error %o", err);
    });
    linkifier.start();
});

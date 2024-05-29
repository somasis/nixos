// ==UserScript==
// @name         Quirks
// @author       Kylie McClain <kylie@somas.is>
// @include      http://*
// @include      https://*
// @grant        GM_addStyle
// ==/UserScript==

(function () {
    "use strict";

    // <https://urlpattern.spec.whatwg.org/>
    // <https://github.com/whatwg/urlpattern/blob/main/mdn-drafts/QUICK-REFERENCE.md>
    // <https://developer.mozilla.org/en-US/docs/Web/API/URLPattern/URLPattern>
    function matchURL(URLPatternArgs) {
        return new URLPattern(URLPatternArgs).test(document.location);
    }

    function matchAnyURL(URLPatternArgsList) {
        if ((typeof URLPatternArgsList) != "list") {
            throw new Error("argument must be list");
        }

        var matched = false;

        for (const URLPatternArgs of URLPatternArgsList) {
            if (matchURL(URLPatternArgs)) matched = true;
        }

        return matched;
    }

    var style = "";

    /* Disable all element animations, unless they're a list of exceptions;
     *  some stupid sites never hide their animation elements for some reason,
     *  which causes issues if you disable animations entirely... */
    if (!matchURL({ hostname: "{:www.}?paypal.com" }))
        style += `
          * {
            animation: none !important;
            transition: none !important;
          }
        `;

    /* Redirect ASuLearn item pages with non-fullscreen iframes embeds (i.e.
     * they're probably not a video or some other type of media) on them to
     * their source URL; this is useful for when instructors use tools external
     * to ASuLearn, like Packback. */
    if (
        matchURL({
            hostname: "asulearn.appstate.edu",
            pathname: ".*/view.php",
        }) &&
        document.querySelector(
            "#page-content iframe#contentframe[allowfullscreen=true]",
        ) != null
    )
        document.location = document.getElementById("contentframe").src;

    if (matchURL({ hostname:"ebscohost.com" })) {
      if (matchURL({ pathname: "openurl" }) && document.querySelector("span#errorText a") != null && document.querySelector("iframe#external-frame") != null)
          document.location = document.querySelector("span#errorText a").href;

      if (matchURL({ pathname: ".*/pdfviewer" }))
          document.location = document.querySelector("iframe#pdfIframe").href;
    }

    // if (document.location.hostname == "bsky.app")
    //     style += `
    //         body {
    //             overflow-y: hidden !important;
    //         }

    //         .r-1owuwv7 {
    //             scrollbar-gutter: initial !important;
    //         }
    //     `;

    if (style != "") GM_addStyle(style);
})();

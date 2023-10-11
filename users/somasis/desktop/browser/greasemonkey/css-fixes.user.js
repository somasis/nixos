// ==UserScript==
// @name         Fix CSS issues
// @author       Kylie McClain <kylie@somas.is>
// @include      http://*
// @include      https://*
// @grant        GM_addStyle
// ==/UserScript==

(function () {
        "use strict";

        function matchURL(URLPatternArgs) {
                return new URLPattern(URLPatternArgs).test(document.location);
        }

        var style = "";
        var doneApplying = false;

        if (matchURL({ hostname: "jira.appstate.edu" }))
                style += `
        body#jira .page-type-navigator {
            overflow-y: hidden !important;
        }
    `;

        if (
                matchURL({
                        hostname: "asulearn.appstate.edu",
                        pathname: "/mod/lti/view.php",
                        search: "?id=3576209",
                })
        )
                document.location = document.getElementById("contentframe").src;

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

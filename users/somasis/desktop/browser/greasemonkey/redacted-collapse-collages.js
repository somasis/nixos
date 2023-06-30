// ==UserScript==
// @name         RED: Collapse all collages
// @version      0.1
// @include      http*://*redacted.ch/userhistory.php?action=subscribed_collages
// ==/UserScript==

(function() {
    'use strict';
    $('.colhead_dark a:contains("Hide")').click();
})();

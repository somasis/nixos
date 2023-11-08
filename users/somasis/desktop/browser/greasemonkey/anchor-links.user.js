// ==UserScript==
// @name         Anchor links
// @description  Add a link to headings with anchors
// @author       Kylie McClain <kylie@somas.is>
// @license      MIT
// @include      http://*
// @include      https://*
// @grant        GM_addStyle
// ==/UserScript==

function createLink(href) {
  var link = document.createElement("a");
  link.classList.add("somasis-anchor");
  link.innerHTML = "&#x1F517;&#xFE0E;&nbsp;";
  link.href = href;
  return link;
}

(function () {
  "use strict";

  GM_addStyle(`
    a.somasis-anchor {
        filter: grayscale(100%) sepia(500%) contrast(500%) brightness(0%);
        font-size: .65em;
        user-select: none;
        vertical-align: middle;
        text-decoration: none;
    }

    :hover > a.somasis-anchor, :focus > a.somasis-anchor {
        display: inline;
    }
  `);

  var anchors = document.querySelectorAll(
    `h2[id], h2 [id], h3[id], h3 [id], h4[id], h4 [id], h5[id], h5 [id], h6[id], h6 [id]`,
  );

  for (var elem of anchors) {
    // Only add anchor links to anchors that don't already have them.
    var elemHasLinks =
      elem.querySelectorAll(`a:link[href="#${elem.id}"]`).length > 0;
    if (!elemHasLinks) elem.prepend(createLink("#" + elem.id));
  }
})();

// ==UserScript==
// @name            Make ReCaptcha's "I'm not a robot" accurate
// @description     Ported from the original WebExtension, adding support for hCaptcha
// @version         0.1
// @author          Kylie McClain <kylie@somas.is> (Greasemonkey port)
// @author          AJ Jordan <alex@strugee.net> (original WebExtension version <https://github.com/strugee/recaptcha-unpaid-labor>)
// @namespace       https://somas.is
// @include         *
// ==/UserScript==

// (function () {
// 'use strict';

// var hcaptcha = document.location.hostname.endsWith("hcaptcha.com");
var recaptcha = document.getElementsByClassName("g-recaptcha");

try {
  // if (hcaptcha) var label = document.getElementById("label");
  if (recaptcha) var label = document.getElementById("recaptcha-anchor-label");

  if (label != undefined) {
    label.innerText = "I want to do unpaid image classification";
    console.log("Replaced captcha text successfully.");
  }
} catch ({ name, message }) {
  console.log(`Failed to replace captcha label: ${name}: ${message}`);
}

// })();

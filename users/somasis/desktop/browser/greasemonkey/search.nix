{ pkgs
, config
, ...
}: {
  programs.qutebrowser.greasemonkey = map config.lib.somasis.drvOrPath [
    # Google
    (pkgs.fetchurl { hash = "sha256-azHAQKmNxAcnyc7l08oW9X6DuMqAblFGPwD8T9DsrSs="; url = "https://greasyfork.org/scripts/32635-disable-google-search-result-url-redirector/code/Disable%20Google%20Search%20Result%20URL%20Redirector.user.js"; })
    (pkgs.fetchurl { hash = "sha256-Bb1QsU6R9xU718hRskGbuwNO7rrhuV7S1gvKtC9SlL0="; url = "https://greasyfork.org/scripts/37166-add-site-search-links-to-google-search-result/code/Add%20Site%20Search%20Links%20To%20Google%20Search%20Result.user.js"; })
    (pkgs.fetchurl { hash = "sha256-5C7No5dYcYfWMY+DwciMeBmkdE/wnplu5fxk4q7OFZc="; url = "https://greasyfork.org/scripts/382039-speed-up-google-captcha/code/Speed%20up%20Google%20Captcha.user.js"; })
    ((pkgs.fetchFromGitHub { owner = "jmlntw"; repo = "google-search-sidebar"; rev = "0e8e94c017681447cd9a21531d4cab7427f44022"; hash = "sha256-6bRzZTXYnAIsWJZQqfgmxdzeQOVk6H5swbCduCkqqIw="; }) + "/dist/google-search-sidebar.user.js")
    (pkgs.fetchurl { hash = "sha256-r4UF6jr3jhVP7JxJNPBzEpK1fkx5t97YWPwf37XLHHE="; url = "https://greasyfork.org/scripts/383166-google-images-search-by-paste/code/Google%20Images%20-%20search%20by%20paste.user.js"; })
    (pkgs.fetchurl { hash = "sha256-O+CuezLYKcK2Qh4jq4XxrtEEIPKOaruHnUGQNwkkCF8="; url = "https://greasyfork.org/scripts/381497-reddit-search-on-google/code/Reddit%20search%20on%20Google.user.js"; })
  ];
}

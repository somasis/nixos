# TODO: Replace with age-based password store when Android
#       Password Store is usable with it

{ config
, pkgs
, osConfig
, lib
, ...
}: {
  persist.directories = [
    ".gnupg"
    { method = "symlink"; directory = config.lib.somasis.xdgDataDir "password-store"; }
  ];

  programs.gpg.enable = true;
  services.gpg-agent = {
    enable = true;
    enableExtraSocket = true;
    enableSshSupport = false;
    pinentryFlavor = "gtk2";
  };

  programs.password-store = {
    enable = true;

    settings.PASSWORD_STORE_CLIP_TIME = builtins.toString 60;

    package = pkgs.pass-nodmenu.withExtensions (exts: with exts; [
      pass-checkup
      pass-update

      pass-otp
      (pkgs.stdenvNoCC.mkDerivation rec {
        name = "pass-botp";

        src = pkgs.fetchFromGitHub {
          repo = "pass-botp";
          owner = "msmol";
          rev = "0b0f3e2f7b0ef349fcf6c1cdfc08f5ccdad6b8d1";
          hash = "sha256-63oNeGNUa9TMmxv+5mS1kj44HKajbc0ytQskYIq1YXQ=";
        };

        installPhase = ''
          install -D -m755 $src/src/botp.bash $out/lib/password-store/extensions/botp.bash
        '';
      })

      pkgs.pass-meta
      # pkgs.pass-link
    ]);
  };

  # Provide libsecret service for various apps
  services.pass-secret-service.enable = true;

  programs.qutebrowser =
    let
      dmenu = config.programs.dmenu.package;
      pass = config.programs.password-store.package;
      dmenu-pass = pkgs.dmenu-pass.override { inherit dmenu pass; };
      qute-pass = pkgs.qute-pass.override { inherit dmenu-pass pass; };
    in
    {
      keyBindings.normal."zlg" = "pass -m generate-for-url {url:host}";
      keyBindings.normal."zlG" = "pass -m generate-for-url -n {url:host}";

      # selectors for username/password/otp input boxes. I know right
      extraConfig =
        let
          flatMap = f: l: lib.flatten (map f l);
          quote = q: s: "${q}${lib.escape [ q ] s}${q}";

          # ensure that specific forms come before non-specific
          inForms = l:
            [ ]
            ++ (flatMap (x: ''form[id*=log_in i] ${x}'') l)
            ++ (flatMap (x: ''form[id*=log-in i] ${x}'') l)
            ++ (flatMap (x: ''form[id*=login i] ${x}'') l)
            ++ (flatMap (x: ''form[id*=sign_in i] ${x}'') l)
            ++ (flatMap (x: ''form[id*=sign-in i] ${x}'') l)
            ++ (flatMap (x: ''form[id*=signin i] ${x}'') l)
            ++ (flatMap (x: ''form ${x}'') l)
          ;

          # ensure autocompletes come first
          asNames = l:
            [ ]
            ++ (flatMap (x: [ ''[autocomplete=${x} i]'' ''[autocomplete~=${x} i]'' ''[autocomplete*=${x} i]'' ]) l)
            ++ (flatMap (x: [ ''[name=${x} i]'' ''[id=${x} i]'' ''[placeholder=${x} i]'' ''[aria-label=${x} i]'' ]) l)
            ++ (flatMap (x: [ ''[name~=${x} i]'' ''[id~=${x} i]'' ''[placeholder~=${x} i]'' ''[aria-label~=${x} i]'' ]) l)
            ++ (flatMap (x: [ ''[name*=${x} i]'' ''[id*=${x} i]'' ''[placeholder*=${x} i]'' ''[aria-label*=${x} i]'' ]) l)
          ;

          # ensure that we prioritize required/autofocused forms before all else
          preferSpecial = l:
            [ ]
            ++ (map (x: "${x}[required][autofocus]") l)
            ++ (map (x: "${x}[required]") l)
            ++ (map (x: "${x}[autofocus]") l)
            ++ l
          ;

          # generate a list with a whole lot of selectors in highest to lowest priority
          # start with the element that we need to check multiple of, then process it
          # a few times
          #
          # process:
          #     1. Start with "username", wrapped in quotes to create '"username"', and pass it to `asNames`
          #     2. asNames generates
          #       [
          #         ''[autocomplete="username" i]'', ''[autocomplete~="username" i]'', ''[autocomplete*="username" i]'',i
          #         ''[name="username" i]'', ''[id="username" i]'', ''[placeholder="username" i]'', ''[aria-label="username" i]'',
          #         ''[name~="username" i]'', ''[id~="username" i]'', ''[placeholder~="username" i]'', ''[aria-label~="username" i]'',
          #         ''[name*="username" i]'', ''[id*="username" i]'', ''[placeholder*="username" i]'', ''[aria-label*="username" i]''
          #       ]
          #       and passes it to the next function.
          #     3. Prefix each item with 'input[type="text"]
          #     4. Receive list `x`, and generate once big list that is each item in
          #        `x` with '[required][autofocus]' appended,
          #        then `x` with '[required]' appended,
          #        then `x` with '[autofocus]' appended,
          #        then `x` again, in that order.
          #     5. Append the form selectors to each time, same process but with
          #        'form[id*=login i] ' and 'form ' so that we prefer login forms before
          #        any other forms.
          #     ∴  giant huge priority-sorted list of selectors
          usernameSelectors = lib.pipe (map (quote "\"") [ "login" "user" "alias" "username" "" ]) [
            asNames
            (map (x: ''input[type="text"]${x}''))
            preferSpecial
            inForms
          ];

          emailSelectors = lib.pipe (map (quote "\"") [ "email" "" ]) [
            asNames
            (flatMap (x: [ ''input[type="email"]${x}'' ''input[type="text"]${x}'' ]))
            preferSpecial
            inForms
          ];

          passwordSelectors = lib.pipe (map (quote "\"") [ "current-password" "password" "" ]) [
            asNames
            (map (x: ''input[type="password"]${x}''))
            preferSpecial
            inForms
          ];

          newPasswordSelectors = lib.pipe (map (quote "\"") [ "new-password" "password" "" ]) [
            asNames
            (map (x: ''input[type="password"]${x}''))
            preferSpecial
            inForms
          ];

          otpSelectors = lib.pipe (map (quote "\"") [ "otp" "2fa" "" ]) [
            asNames
            (map (x: ''input[type="number"]${x}''))
            preferSpecial
            inForms
          ];

          # cardSelectors = lib.pipe (map (quote "\"") [ "credit" "card" [
          #   asNames
          #   (map (x: ''input[type="text"]${x}''))
          #   inForms
          # ];

          # cvvSelectors = lib.pipe (map (quote "\"") [ "cvv" [
          #   asNames
          #   (map (x: ''input[type="text"]${x}''))
          #   inForms
          # ];

          # stolen from browserpass
          # <https://github.com/browserpass/browserpass-extension/blob/858cc821d20df9102b8040b78d79893d4b7af352/src/inject.js#L62-L134>
          submitSelectors = lib.pipe
            [
              "[type=submit i]"
              "button[name=login i]"
              "button[name=log-in i]"
              "button[name=log_in i]"
              "button[name=signin i]"
              "button[name=sign-in i]"
              "button[name=sign_in i]"
              "button[id=login i]"
              "button[id=log-in i]"
              "button[id=log_in i]"
              "button[id=signin i]"
              "button[id=sign-in i]"
              "button[id=sign_in i]"
              "button[class=login i]"
              "button[class=log-in i]"
              "button[class=log_in i]"
              "button[class=signin i]"
              "button[class=sign-in i]"
              "button[class=sign_in i]"
              "input[type=button i][name=login i]"
              "input[type=button i][name=log-in i]"
              "input[type=button i][name=log_in i]"
              "input[type=button i][name=signin i]"
              "input[type=button i][name=sign-in i]"
              "input[type=button i][name=sign_in i]"
              "input[type=button i][id=login i]"
              "input[type=button i][id=log-in i]"
              "input[type=button i][id=log_in i]"
              "input[type=button i][id=signin i]"
              "input[type=button i][id=sign-in i]"
              "input[type=button i][id=sign_in i]"
              "input[type=button i][class=login i]"
              "input[type=button i][class=log-in i]"
              "input[type=button i][class=log_in i]"
              "input[type=button i][class=signin i]"
              "input[type=button i][class=sign-in i]"
              "input[type=button i][class=sign_in i]"

              "button[name*=login i]"
              "button[name*=log-in i]"
              "button[name*=log_in i]"
              "button[name*=signin i]"
              "button[name*=sign-in i]"
              "button[name*=sign_in i]"
              "button[id*=login i]"
              "button[id*=log-in i]"
              "button[id*=log_in i]"
              "button[id*=signin i]"
              "button[id*=sign-in i]"
              "button[id*=sign_in i]"
              "button[class*=login i]"
              "button[class*=log-in i]"
              "button[class*=log_in i]"
              "button[class*=signin i]"
              "button[class*=sign-in i]"
              "button[class*=sign_in i]"
              "input[type=button i][name*=login i]"
              "input[type=button i][name*=log-in i]"
              "input[type=button i][name*=log_in i]"
              "input[type=button i][name*=signin i]"
              "input[type=button i][name*=sign-in i]"
              "input[type=button i][name*=sign_in i]"
              "input[type=button i][id*=login i]"
              "input[type=button i][id*=log-in i]"
              "input[type=button i][id*=log_in i]"
              "input[type=button i][id*=signin i]"
              "input[type=button i][id*=sign-in i]"
              "input[type=button i][id*=sign_in i]"
              "input[type=button i][class*=login i]"
              "input[type=button i][class*=log-in i]"
              "input[type=button i][class*=log_in i]"
              "input[type=button i][class*=signin i]"
              "input[type=button i][class*=sign-in i]"
              "input[type=button i][class*=sign_in i]"
            ]
            [
              preferSpecial
              inForms
            ]
          ;

          selectors = {
            username = usernameSelectors;
            # emailSelectors;
            email = emailSelectors;

            password = passwordSelectors;
            new-password = newPasswordSelectors;

            otp = otpSelectors;

            submit = submitSelectors;
          };
        in
        lib.concatStringsSep
          "\n"
          (lib.mapAttrsToList
            (n: v: "c.hints.selectors[${quote "'" n}] = ${builtins.toJSON v}")
            selectors
          )
      ;
    };

  # NOTE Workaround <https://github.com/NixOS/nixpkgs/issues/183604>
  programs.bash.initExtra =
    let
      completions = "${config.programs.password-store.package}/share/bash-completion/completions";
    in
    lib.mkAfter ''
      source ${completions}/pass-*
      source ${completions}/pass
    '';
}

{ pkgs
, lib
, config
, osConfig
, ...
}:
let
  inherit (lib) replaceStrings;
  inherit (config.lib.somasis) commaList xdgCacheDir xdgConfigDir;
  inherit (config.lib.somasis.generators) toXML;

  lo = pkgs.libreoffice-fresh;

  ltVersion = pkgs.languagetool.version;

  loExtensions = [
    # <https://extensions.libreoffice.org/en/extensions/show/27416>
    (pkgs.fetchurl {
      url = "https://extensions.libreoffice.org/assets/downloads/90/1676301090/TemplateChanger-L-2.0.1.oxt";
      hash = "sha256-i1+Huqsq2fYstUS4HevqpNc0/1zKRBQONMz6PB9HYh4=";
    })

    # <https://extensions.libreoffice.org/en/extensions/show/27347>
    (pkgs.fetchurl {
      url = "https://extensions.libreoffice.org/assets/downloads/73/1672894181/open_recent_doc.oxt";
      hash = "sha256-4ZZlqJKPuEw/9Sg7vyjLHERFL9yqWamtwAvldJkgFTg=";
    })

    # <https://extensions.libreoffice.org/en/extensions/show/english-dictionaries>
    (pkgs.fetchurl {
      url = "https://extensions.libreoffice.org/assets/downloads/41/1680302696/dict-en-20230401_lo.oxt";
      hash = "sha256-TXRr6BgGAQ4xKDY19OtowN6i4MdINS2BEtq2zLJDkZ0=";
    })

    # <https://extensions.libreoffice.org/en/extensions/show/spanish-dictionaries>
    (pkgs.fetchurl {
      url = "https://extensions.libreoffice.org/assets/downloads/98/1659525229/es.oxt";
      hash = "sha256-EPpR3/t48PwV/XkXcIE/VR2kPPAHtSy4+2zLC0EX6F8=";
    })

    # <https://extensions.libreoffice.org/en/extensions/show/dictionnaires-francais>
    (pkgs.fetchurl {
      url = "https://extensions.libreoffice.org/assets/downloads/z/lo-oo-ressources-linguistiques-fr-v5-7.oxt";
      hash = "sha256-lHPFZQg2QmN5jYd6wy/oSccQhXNyUXBVQzRsi6NCGt8=";
    })

    # <https://extensions.libreoffice.org/en/extensions/show/german-de-de-frami-dictionaries>
    (pkgs.fetchurl {
      url = "https://extensions.libreoffice.org/assets/downloads/z/dict-de-de-frami-2017-01-12.oxt";
      hash = "sha256-r1FQFeMGxjQ3O1OCgIo5aRIA3jQ5gR0vFQLpuRwjtGo=n";
    })

    # <https://extensions.libreoffice.org/en/extensions/show/latin-spelling-and-hyphenation-dictionaries>
    (pkgs.fetchurl {
      url = "https://extensions.libreoffice.org/assets/downloads/z/dict-la-2013-03-31.oxt";
      hash = "sha256-2DDGbz6Fihz7ruGIoA2HZIL78XK7MgJr3UeeoaYywtI=n";
    })

    # <https://extensions.libreoffice.org/en/extensions/show/languagetool>
    (pkgs.fetchurl {
      url = "https://languagetool.org/download/LanguageTool-${ltVersion}.oxt";
      sha256 = "0f1f39ff2438d322f15962f1d30a5c293bb121a7f709c7bbdc1099636b91625e";
    })
  ]
  ++ lib.optional config.programs.zotero.enable
    "${config.programs.zotero.package}/usr/lib/zotero-bin-${pkgs.zotero.version}/extensions/zoteroOpenOfficeIntegration@zotero.org/install/Zotero_OpenOffice_Integration.oxt"
  ;

  loInstallExtensions =
    assert (builtins.isList loExtensions);
    pkgs.writeShellScript "libreoffice-install-extensions" ''
      PATH=${lib.makeBinPath [ pkgs.gnugrep pkgs.coreutils lo ]}
      ${lib.toShellVar "exts" loExtensions}

      ext_is_installed() {
          for installed_ext in "''${installed_exts[@]}"; do
              installed_ext_basename=''${installed_ext##*/}
              [[ "$1" == "$installed_ext_basename" ]] && return 0
          done
          return 1
      }

      mapfile -t installed_exts < <(unopkg list | grep '^  URL:' | cut -d ' ' -f4-)

      for ext in "''${exts[@]}"; do
          ext_is_installed "$(basename "$ext")" || unopkg add -v -s "$ext"
      done
    '';

  # languageToolConfigFormat = lib.generators.toKeyValue {
  #   mkKeyValue = k: v:
  #     lib.generators.mkKeyValueDefault
  #       {
  #         mkValueString = value:
  #           if lib.isList value then
  #             commaList value
  #           else
  #             lib.escape [ ":" ] (lib.generators.mkValueStringDefault { } value)
  #         ;
  #       } "="
  #       k
  #       v
  #   ;
  # };

  # "Languagetool.cfg" is not a typo.
  # languageToolConfig = pkgs.writeText "Languagetool.cfg" (languageToolConfigFormat rec {
  #   inherit ltVersion;
  #   motherTongue = "en-US";

  #   autoDetect = false;

  #   "disabledCategories.en-US" = [ "Creative Writing" "Wikipedia" ];
  #   "disabledRules.en-US" = [ "HASH_SYMBOL" "WIKIPEDIA_CONTRACTIONS" "WIKIPEDIA_CURRENTLY" "TOO_LONG_SENTENCE" "WIKIPEDIA_12_PM" "WIKIPEDIA_12_AM" ];
  #   "enabledRules.en-US" = [ "THREE_NN" "EN_REDUNDANCY_REPLACE" ];

  #   fixedLanguage = motherTongue;

  #   isMultiThread = true; # Use multiple cores for checking
  #   noDefaultCheck = true;
  #   doRemoteCheck = false; # Check locally
  #   useOtherServer = false; # Check locally

  #   numberParagraphs = -2;

  #   otherServerUrl = "http://127.0.0.1:${builtins.toString config.somasis.tunnels.tunnels.languagetool.port}";

  #   isPremium = true;
  #   # remoteUserName = config.home.username;

  #   taggerShowsDisambigLog = false;

  #   useGUIConfig = false;
  # });

  # loSetLanguageToolConfiguration = pkgs.writeShellScript "libreoffice-set-languagetool-configuration" ''
  #   cat ${languageToolConfig} > "''${XDG_CONFIG_HOME:=$HOME/.config}"/LanguageTool/LibreOffice/Languagetool.cfg
  # '';

  loWrapperBeforeCommands = pkgs.writeShellScript "libreoffice-before-execute" ''
    if [[ "$(pgrep -c -u "''${USER:=$(id -un)}" 'soffice\.bin')" -eq 0 ]]; then
        ${loInstallExtensions} || :
    fi
  '';
  # ${loSetLanguageToolConfiguration} || :

  loWrapped = lo.override {
    extraMakeWrapperArgs = [
      "--add-flags '--nologo'"
      "--run ${loWrapperBeforeCommands}"
    ];
  };
in
rec {
  home.packages = [
    loWrapped

    pkgs.languagetool

    # Free replacements for pkgs.corefonts
    pkgs.caladea # Cambria
    pkgs.carlito # Calibri
    pkgs.comic-relief # Comic Sans MS
    pkgs.gelasio # Georgia
    pkgs.liberation-sans-narrow # Arial Narrow
    pkgs.liberation_ttf # Arial, Helvetica, Times New Roman, Courier New
    pkgs.noto-fonts-extra # Arial, Times New Roman
  ];

  # See for more details:
  # <https://wiki.documentfoundation.org/UserProfile#User_profile_content>
  persist = {
    directories = [{ method = "symlink"; directory = xdgConfigDir "libreoffice/4"; }];
    files = [ (xdgConfigDir "LanguageTool/LibreOffice/Languagetool.cfg") ];
  };

  cache.directories = [
    { method = "symlink"; directory = xdgConfigDir "LanguageTool/LibreOffice/cache"; }
    { method = "symlink"; directory = xdgCacheDir "libreoffice/backups"; }
  ];
  log.files = [ (xdgConfigDir "LanguageTool/LibreOffice/LanguageTool.log") ];

  xdg.configFile = {
    "libreoffice/jre".source = lo.unwrapped.jdk;
    "LanguageTool/LibreOffice/.keep".source = builtins.toFile "keep" "";

    # TODO: why doesn't this work?
    #       LibreOffice will fail to recognize the Java environment at all, if I
    #       generate the javasettings XML file during build time...
    #   let
    #     system = osConfig.nixpkgs.localSystem.uname;
    #   in
    #   {
    #     "libreoffice/4/user/config/javasettings_${system.system}_${lib.toUpper system.processor}.xml".text = toXML {} {
    #       java = {
    #         "@xmlns" = "http://openoffice.org/2004/java/framework/1.0";
    #         "@xmlns:xsi" = "http://www.w3.org/2001/XMLSchema-instance";

    #         enabled."@xsi:nil" = "true";
    #         userClassPath."@xsi:nil" = "false";
    #         vmParameters."@xsi:nil" = "false";
    #         jreLocations."@xsi:nil" = "true";

    #         # We can't use LibreOffice's own buildInput jdk because it's headless.
    #         # javaInfo = let inherit (lo.unwrapped) jdk; in {
    #         javaInfo = let jdk = pkgs.openjdk19; in {
    #           "@xsi:nil" = "false";
    #           "@vendorUpdate" = "2019-07-26"; # ?
    #           "@autoSelect" = "true";
    #           vendor = "N/A";
    #           location = "file://${jdk}/lib/openjdk";
    #           version = replaceStrings [ "+.*" ] [ "" ] jdk.version;
    #           features = 0;
    #           requirements = 1;

    #           vendorData = "660069006C0065003A002F002F002F006E00690078002F00730074006F00720065002F007A003000300066006D0035003200760078007900670069006B007300620067007000770067006D00770036006A00310066006100370062007700360071006E002D006F00700065006E006A0064006B002D00310039002E0030002E0032002B0037002F006C00690062002F006F00700065006E006A0064006B002F006C00690062002F007300650072007600650072002F006C00690062006A0076006D002E0073006F000A002F006E00690078002F00730074006F00720065002F007A003000300066006D0035003200760078007900670069006B007300620067007000770067006D00770036006A00310066006100370062007700360071006E002D006F00700065006E006A0064006B002D00310039002E0030002E0032002B0037002F006C00690062002F006F00700065006E006A0064006B002F006C00690062002F0061006D006400360034002F0063006C00690065006E0074003A002F006E00690078002F00730074006F00720065002F007A003000300066006D0035003200760078007900670069006B007300620067007000770067006D00770036006A00310066006100370062007700360071006E002D006F00700065006E006A0064006B002D00310039002E0030002E0032002B0037002F006C00690062002F006F00700065006E006A0064006B002F006C00690062002F0061006D006400360034002F007300650072007600650072003A002F006E00690078002F00730074006F00720065002F007A003000300066006D0035003200760078007900670069006B007300620067007000770067006D00770036006A00310066006100370062007700360071006E002D006F00700065006E006A0064006B002D00310039002E0030002E0032002B0037002F006C00690062002F006F00700065006E006A0064006B002F006C00690062002F0061006D006400360034002F006E00610074006900760065005F0074006800720065006100640073003A002F006E00690078002F00730074006F00720065002F007A003000300066006D0035003200760078007900670069006B007300620067007000770067006D00770036006A00310066006100370062007700360071006E002D006F00700065006E006A0064006B002D00310039002E0030002E0032002B0037002F006C00690062002F006F00700065006E006A0064006B002F006C00690062002F0061006D006400360034000A00"; # wtf
    #         };
    #       };
    #     };
  };

  xdg.mimeApps.associations.removed = lib.genAttrs [ "text/plain" ] (_: "libreoffice.desktop");

  # Do some really convoluted stuff to make LibreOffice run in the background.
  # systemd.user.services.libreoffice = {
  #   Unit = {
  #     Description = lo.meta.description;
  #     PartOf = [ "graphical-session.target" ];
  #   };
  #   Install.WantedBy = [ "graphical-session.target" ];

  #   Service =
  #     let
  #       loWait = pkgs.writeShellScript "libreoffice-wait" ''
  #         ${pkgs.procps}/bin/pwait -u "$USER" "soffice.bin" || :
  #         ${pkgs.coreutils}/bin/rm -f ${lib.escapeShellArg config.xdg.configHome}/libreoffice/4/.lock
  #       '';
  #     in
  #     {
  #       Type = "simple";

  #       # Only run the daemon during school. Saves memory.
  #       # ExecCondition = [ "${pkgs.playtime}/bin/playtime -iq" ];

  #       # Wait for any standalone instances of libreoffice to quit; there might be one open,
  #       # which will cause ExecStart to fail if we don't wait for it to end by itself.
  #       # We especially do not want to kill it since it might be some in-progress writing.
  #       # If there is no process matching the pattern, pwait will exit non-zero.
  #       ExecStartPre =
  #         [ "-${loWait}" ]
  #         ++ [
  #           loInstallExtensions
  #           loSetLanguageToolConfiguration
  #         ]
  #       ;

  #       ExecStart = [ "${lo}/bin/soffice --quickstart --nologo --nodefault" ];

  #       Restart = "always";
  #       RestartSec = 0;

  #       KillSignal = "SIGQUIT";

  #       # If using `--headless`, things get echoed to the standard output of this process... :|
  #       StandardOutput = "null";
  #     };
  # };

  # services.sxhkd.keybindings."@F1" = pkgs.writeShellScript "conditional-f1" ''
  #   case "$(xprop -id "$(xdotool getactivewindow)" WM_CLASS in
  #       libreoffice*
  #   pkill -USR2 -x sxhkd
  #   ${pkgs.xdotool}/bin/xdotool key F1
  #   pkill -USR2 -x sxhkd
  # '';

  somasis.tunnels.tunnels.languagetool = {
    port = 3864;
    remote = "somasis@spinoza.7596ff.com";
    linger = "15m";
  };

  home.sessionVariables = {
    LANGUAGETOOL_HOSTNAME = "127.0.0.1";
    LANGUAGETOOL_PORT = builtins.toString somasis.tunnels.tunnels.languagetool.port;
  };
}

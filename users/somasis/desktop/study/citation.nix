{ pkgs
, config
, lib
, osConfig
, inputs
, ...
}:
let
  inherit (config.lib.somasis) flakeModifiedDateToVersion;
  inherit (osConfig.services) tor;

  qutebrowser-zotero = pkgs.callPackage
    ({ lib, fetchurl, fetchFromGitHub, python3Packages }:
      python3Packages.buildPythonApplication rec {
        pname = "qutebrowser-zotero";
        version = flakeModifiedDateToVersion inputs.qutebrowser-zotero;
        # version = "unstable-2019-06-15";

        format = "other";

        src = inputs.qutebrowser-zotero;
        # src = fetchFromGitHub {
        #   owner = "parchd-1";
        #   repo = "qutebrowser-zotero";
        #   rev = "54706b43433c3ea8da6b7b410d67528da9779657";
        #   hash = "sha256-Jv5qrpWSMrfGr6gV8PxELCOfZ0PyGBPO+nBt2czYuu4=";
        # };

        propagatedBuildInputs = with python3Packages; [ requests ];

        installPhase = ''
          install -m0755 -D $src/qute-zotero $out/bin/qute-zotero
        '';

        meta = with lib; {
          description = "Connect qutebrowser to a running Zotero instance";
          homepage = "https://github.com/parchd-1/qutebrowser-zotero";
          maintainers = with maintainers; [ somasis ];
          license = licenses.gpl3;
          mainProgram = "qute-zotero";
        };
      })
    { };

  # Use Appalachian State University's proxy
  proxy = "https://login.proxy006.nclive.org/login";
in
{
  programs.zotero = {
    enable = true;

    # package = pkgs.wrapCommand {
    #   package = pkgs.zotero;

    #   wrappers = [{
    #     command = "/bin/zotero";

    #     # Ensure that there isn't a mismatch between extension settings
    #     # (which could get modified during runtime, and then be written
    #     # to prefs.js by Zotero) and our user.js.
    #     beforeCommand =
    #       let
    #         prefs = "${config.home.homeDirectory}/.zotero/zotero/${config.programs.zotero.profiles.default.path}/prefs.js";
    #         managedPrefs = lib.concatStringsSep " " (map (x: "-e 'user_pref(\"${x}\", '") (builtins.attrNames config.programs.zotero.profiles.default.settings));

    #         startService = pkgs.writeShellScript "start-zotero-service" ''
    #           ${pkgs.systemd}/bin/systemctl --user is-active -q zotero.service \
    #               || ${pkgs.systemd}/bin/systemctl --user start zotero.service
    #         '';

    #         unhideZotero = pkgs.writeShellScript "zotero-unhide" ''
    #           export PATH=${lib.makeBinPath [ pkgs.xdotool config.xsession.windowManager.bspwm.package ]}:"$PATH"

    #           # Get only a window that matches class=zotero and role=browser,
    #           # which matches to the main Zotero window.
    #           if wid=$(xdotool search --limit 1 --all --class --role 'zotero|browser'); then
    #               if [ -n "$(bspc query -N "$wid"'.hidden')" ]; then # window isn't hidden
    #                   # If the window is hidden on a different desktop, bspwm
    #                   # will not unhide and refocus it on the current desktop-
    #                   # it will unhide and then focus its own desktop. This
    #                   # is different from, say, activating a running instance
    #                   # of Discord, so it trips me up. Move it to the focused
    #                   # desktop when this is the case.
    #                   bspc node "$wid" -g hidden=off -d focused -f
    #               else
    #                   # If it is not hidden, just focus it on the desktop it is on.
    #                   bspc node "$wid" -g hidden=off -f
    #               fi

    #               _skip=true
    #           fi
    #         '';

    #         filterPrefs = pkgs.writeShellScript "filter-prefs" ''
    #           export PATH="${lib.makeBinPath [ pkgs.coreutils pkgs.gnugrep pkgs.moreutils ]}:$PATH"

    #           touch "${prefs}"
    #           grep -vF ${managedPrefs} "${prefs}" | sponge "${prefs}"
    #         '';
    #       in
    #       [
    #         ''[ -z "$_skip" ] && . ${startService}''
    #         ''[ -z "$_skip" ] && . ${unhideZotero}''
    #         ''[ -z "$_skip" ] && ${filterPrefs}''
    #         ''[ -n "$_skip" ] && unset _skip''
    #       ];
    #   }];
    # };

    profiles.default = {
      # TODO installation seems broken?
      # extensions = with pkgs.zotero-addons; [
      #   cita
      #   zotero-abstract-cleaner
      #   zotero-auto-index
      #   zotero-ocr
      #   zotero-open-pdf
      #   zotero-preview
      #   zotero-robustlinks
      #   zotero-storage-scanner
      #   zotfile
      #   zotero-delitemwithatt
      # ];

      settings =
        let
          # Chicago Manual of Style [latest] edition (note)
          style = "http://www.zotero.org/styles/chicago-note-bibliography";
          locale = "en-US";
        in
        rec
        {
          # See <https://www.zotero.org/support/preferences/hidden_preferences> also.

          # HACK: Workaround for Cita addon error
          # <https://github.com/diegodlh/zotero-cita/issues/247>
          "intl.locale.requested" = "en-CA"; # locale;
          "intl.accept_language" = "en-US, en";

          # Use Appalachian State University's OpenURL resolver
          "extensions.zotero.openURL.resolver" = "${proxy}?url=https://resolver.ebscohost.com/openurl?";
          "extensions.zotero.findPDFs.resolvers" = [
            {
              "name" = "Sci-Hub";
              "method" = "GET";
              "url" = "https://sci-hub.ru/{doi}";
              "mode" = "html";
              "selector" = "#pdf";
              "attribute" = "src";
              "automatic" = true;
            }
            {
              "name" = "Google Scholar";
              "method" = "GET";
              "url" = "{z:openURL}https://scholar.google.com/scholar?q=doi%3A{doi}";
              "mode" = "html";
              "selector" = ".gs_or_ggsm a:first-child";
              "attribute" = "href";
              "automatic" = true;
            }
          ];

          # Sort settings
          "extensions.zotero.sortAttachmentsChronologically" = true;
          "extensions.zotero.sortNotesChronologically" = true;

          # Item adding settings
          "extensions.zotero.automaticSnapshots" = false; # Take snapshots of webpages when items are made from them
          "extensions.zotero.translators.RIS.import.ignoreUnknown" = false; # Don't discard unknown RIS tags when importing
          "extensions.zotero.translators.attachSupplementary" = true; # "Translators should attempt to attach supplementary data when importing items"

          # Citation settings
          "extensions.zotero.export.lastStyle" = style;
          "extensions.zotero.export.quickCopy.locale" = locale;
          "extensions.zotero.export.quickCopy.setting" = "bibliography=${style}";
          "extensions.zotero.export.citePaperJournalArticleURL" = false;
          "extensions.zoteropreview.citationstyle" = style; # Zotero Citation Preview

          # Feed options
          "extensions.zotero.feeds.defaultTTL" = 24 * 7; # Refresh feeds every week
          "extensions.zotero.feeds.defaultCleanupReadAfter" = 60; # Clean up read feed items after 60 days
          "extensions.zotero.feeds.defaultCleanupUnreadAfter" = 90; # Clean up unread feed items after 90 days

          # Attachment settings
          "extensions.zotero.useDataDir" = true;
          "extensions.zotfile.useZoteroToRename" = false; # ZotFile > Renaming Rules > "Use Zotero to Rename";

          # Annotation/note settings
          "extensions.zotfile.pdfExtraction.localeDateInNote" = false;
          "extensions.zotfile.pdfExtraction.isoDate" = true; # Use YYYY-MM-DD in the note titles
          "extensions.zotfile.pdfExtraction.UsePDFJS" = true; # ZotFile > Advanced Settings > "Extract annotations..." > "Use pdf.js to extract annotations"

          # Reading settings
          "extensions.zotero.tabs.title.reader" = "filename"; # Show filename in tab title

          # Sync settings
          "extensions.zotero.sync.storage.enabled" = false; # File synchronization is handled by Syncthing.

          # ZotFile > Renaming Rules > "Format for all Item Types except Patents"
          # [Last, First - ]title[ (volume)][ ([year][, book title/journal/publisher/meeting])]
          "extensions.zotfile.renameFormat" = "{%g - }%t{ (%v)}{ (%y{, %B|, %w})}";

          # Custom wildcards
          "extensions.zotfile.wildcards.user" = builtins.toString (builtins.toJSON {
            "B" = "bookTitle"; # %B: For book sections.
            "4" = {
              field = "dateAdded";
              operations = [{
                flags = "g";
                function = "replace";
                regex = "(\\d{4})-(\\d{2})-(\\d{2})(.*)";
                replacement = "$1$2$3";
              }];
            };
          });

          "extensions.zotfile.authors_delimiter" = ", "; # ZotFile > Renaming Rules > "Delimiter between multiple authors"

          "extensions.zotfile.truncate_title" = true; # ZotFile > Renaming Rules > "Truncate title after . or : or ?"

          "extensions.zotfile.truncate_title_max" = true; # ZotFile > Renaming Rules > "Maximum length of title"
          "extensions.zotfile.max_titlelength" = 80;

          "extensions.zotfile.truncate_authors" = true; # ZotFile > Renaming Rules > "Maximum number of authors"
          "extensions.zotfile.max_authors" = 2; # ZotFile > Renaming Rules > "Maximum number of authors"

          "extensions.zotfile.removeDiacritics" = true; # ZotFile > Advanced Settings > "Remove special characters (diacritics) from filename"

          "extensions.zotero.attachmentRenameFormatString" = "{%c - }%t{100}{ (%y)}"; # Set the file name format used by Zotero's internal stuff

          "extensions.zotfile.import" = false; # ZotFile > Location of Files > Custom Location
          "extensions.zotero.autoRenameFiles.linked" = true; # ZotFile > General Settings > Location of Files > Custom Location

          # ZotFile > Advanced Settings > "Only work with the following filetypes"
          "extensions.zotfile.useFileTypes" = true;
          "extensions.zotfile.filetypes" = lib.concatStringsSep "," [
            "pdf"
            "epub"
            "docx"
            "odt"
          ];

          "extensions.zotero.autoRenameFiles.fileTypes" = lib.concatStringsSep "," [
            "application/pdf"
            "application/epub+zip"
            "application/vnd.openxmlformats-officedocument.wordprocessingml.document"
            "application/vnd.oasis.opendocument.text"
          ];

          "extensions.zotfile.confirmation" = false; # ZotFile > Advanced Settings > "Ask user when attaching new files"
          "extensions.zotfile.confirmation_batch" = 0;
          "extensions.zotfile.confirmation_batch_ask" = false; # ZotFile > Advanced Settings > "Ask user to (batch) rename or move [0] or more attachments
          "extensions.zotfile.automatic_renaming" = 3; # ZotFile > Advanced Settigns > "Automatically rename new attachments" > "Always ask (non-disruptive)"

          # Zotero AutoIndex
          "extensions.zotero.fulltext.pdfMaxPages" = 1024;

          # Zotero OCR
          "extensions.zotero.zoteroocr.pdftoppmPath" = "${pkgs.poppler_utils}/bin/pdftoppm";
          "extensions.zotero.zoteroocr.ocrPath" = "${pkgs.tesseract5}/bin/tesseract";

          "extensions.zotero.zoteroocr.outputPDF" = true; # Output options > "Save output as a PDF with text layer"
          "extensions.zotero.zoteroocr.overwritePDF" = true; # Output options > "Save output as a PDF with text layer" > "Overwrite the initial PDF with the output"

          "extensions.zotero.zoteroocr.outputHocr" = false; # Output options > "Save output as a HTML/hocr file(s)"
          "extensions.zotero.zoteroocr.outputNote" = false; # Output options > "Save output as a note"
          "extensions.zotero.zoteroocr.outputPNG" = false; # Output options > "Save the intermediate PNGs as well in the folder"

          # Zotero PDF Preview
          "extensions.zotero.pdfpreview.previewTabName" = "PDF"; # Default tab name clashes with Zotero Citation Preview

          "ui.use_activity_cursor" = true;

          # LibreOffice extension settings
          "extensions.zotero.integration.useClassicAddCitationDialog" = true;
          "extensions.zoteroOpenOfficeIntegration.installed" = true;
          "extensions.zoteroOpenOfficeIntegration.skipInstallation" = true;

          "extensions.shortdoi.tag_invalid" = "#invalid_doi";
          "extensions.shortdoi.tag_multiple" = "#multiple_doi";
          "extensions.shortdoi.tag_nodoi" = "#no_doi";

          "extensions.zotero.automaticScraperUpdates" = true;

        };

      # TODO Hide all chrome: need to find a way to toggle this with <F1>.
      # userChrome = ''
      #   .chromeclass-menubar,
      #   .chromeclass-toolbar {
      #         display: none !important;
      #   }
      # '';
    };
  };

  persist = {
    directories = [
      { method = "bindfs"; directory = ".zotero/zotero/default"; }

      { method = "bindfs"; directory = config.lib.somasis.xdgDataDir "zotero/styles"; }
      { method = "bindfs"; directory = config.lib.somasis.xdgDataDir "zotero/translators"; }
    ];
    files = [ "share/zotero/zotero.sqlite" ];
  };

  xdg.dataFile = {
    "zotero/storage".source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/study/zotero";

    "zotero/locate/.keep".source = builtins.toFile "keep" "";
    "zotero/locate/engines.json".text = builtins.toJSON [
      {
        _hidden = false;

        _name = "WorldCat";
        _alias = "WorldCat";
        _description = "WorldCat Search";
        _icon = "https://worldcat.org/favicons/favicon-16x16.png";

        _urlTemplate = "https://worldcat.org/search?q=bn%3A{rft:isbn}+AND+ti%3A{z:title}+AND+au%3A{rft:aufirst?}+{rft:aulast?}";
        _urlParams = [ ];

        _urlNamespaces = {
          "" = "http://a9.com/-/spec/opensearch/1.1/";
          z = "http://www.zotero.org/namespaces/openSearch#";
          rft = "info:ofi/fmt:kev:mtx:book";
        };
      }

      {
        _hidden = false;

        _name = "CrossRef Lookup";
        _alias = "CrossRef";
        _description = "CrossRef Search Engine";
        _icon = "https://crossref.org/favicon.ico";

        _urlTemplate = "https://crossref.org/openurl?{z:openURL}&pid=zter:zter321";
        _urlParams = [ ];

        _urlNamespaces = {
          "" = "http://a9.com/-/spec/opensearch/1.1/";
          z = "http://www.zotero.org/namespaces/openSearch#";
        };
      }

      {
        _hidden = false;

        _name = "Google Scholar";
        _alias = "Google Scholar";
        _description = "Google Scholar Search";
        _icon = "https://scholar.google.com/favicon.ico";

        _urlTemplate = "https://scholar.google.com/scholar?as_q=&as_epq={z:title}&as_occt=title&as_sauthors={rft:aufirst?}+{rft:aulast?}&as_ylo={z:year?}&as_yhi={z:year?}&as_sdt=1.&as_sdtp=on&as_sdtf=&as_sdts=22&";
        _urlParams = [ ];

        _urlNamespaces = {
          "" = "http://a9.com/-/spec/opensearch/1.1/";
          z = "http://www.zotero.org/namespaces/openSearch#";
          rft = "info:ofi/fmt:kev:mtx";
        };
      }
      {
        _hidden = false;

        _name = "Google Scholar (title only)";
        _alias = "Google Scholar (title)";
        _description = "Google Scholar Search (title only)";
        _icon = "https://scholar.google.com/favicon.ico";

        _urlTemplate = "https://scholar.google.com/scholar?as_q=&as_epq={z:title}&as_occt=title&as_sdt=1.&as_sdtp=on&as_sdtf=&as_sdts=22&";
        _urlParams = [ ];

        _urlNamespaces = {
          "" = "http://a9.com/-/spec/opensearch/1.1/";
          z = "http://www.zotero.org/namespaces/openSearch#";
          rft = "info:ofi/fmt:kev:mtx:book";
        };
      }

      {
        _hidden = false;

        _name = "Thriftbooks";
        _alias = "Thriftbooks";
        _description = "Search Thriftbooks";
        _icon = "https://static.thriftbooks.com/images/favicon.ico";

        _urlTemplate = "https://www.thriftbooks.com/viewDetails.aspx?ASIN={rft:isbn}";
        _urlParams = [ ];

        _urlNamespaces = {
          "" = "http://a9.com/-/spec/opensearch/1.1/";
          z = "http://www.zotero.org/namespaces/openSearch#";
          rft = "info:ofi/fmt:kev:mtx:book";
        };
      }

      {
        _hidden = false;

        _name = "Abebooks";
        _alias = "Abebooks";
        _description = "Search Abebooks";
        _icon = "https://www.abebooks.com/favicon.ico";

        _urlTemplate = "https://www.abebooks.com/servlet/SearchResults?isbn={rft:isbn}";
        _urlParams = [ ];

        _urlNamespaces = {
          "" = "http://a9.com/-/spec/opensearch/1.1/";
          z = "http://www.zotero.org/namespaces/openSearch#";
          rft = "info:ofi/fmt:kev:mtx:book";
        };
      }

      {
        _hidden = false;

        _name = "Anna's Archive";
        _alias = "Anna's";
        _description = "Search Anna's Archive";
        _icon = "https://annas-archive.org/favicon-32x32.png";

        _urlTemplate = "https://annas-archive.org/search?index=&q={rft:isbn}";
        _urlParams = [ ];

        _urlNamespaces = {
          "" = "http://a9.com/-/spec/opensearch/1.1/";
          z = "http://www.zotero.org/namespaces/openSearch#";
          rft = "info:ofi/fmt:kev:mtx:book";
        };
      }

      {
        _hidden = false;

        _name = "Library Genesis";
        _alias = "Library Genesis";
        _description = "Search Library Genesis";
        _icon = "http://libgen.rs/favicon.ico";

        _urlTemplate = "http://libgen.rs/search.php?req={rft:isbn}&open=0&res=25&view=detailed&phrase=1&column=identifier";
        _urlParams = [ ];

        _urlNamespaces = {
          "" = "http://a9.com/-/spec/opensearch/1.1/";
          z = "http://www.zotero.org/namespaces/openSearch#";
          rft = "info:ofi/fmt:kev:mtx:book";
        };
      }

      {
        _hidden = false;

        _name = "12ft.io";
        _alias = "12ft.io";
        _description = "Show me a 10ft paywall, I'll show you a 12ft ladder";
        _icon = "https://12ft.io/favicon.png";

        _urlTemplate = "https://12ft.io/api/proxy?q={z:url}";
        _urlParams = [ ];

        _urlNamespaces = {
          "" = "http://a9.com/-/spec/opensearch/1.1/";
          z = "http://www.zotero.org/namespaces/openSearch#";
        };
      }
      {
        _hidden = false;

        _name = "Unpaywall";
        _alias = "Unpaywall";
        _description = "Unpaywall Lookup";
        _icon = "https://oadoi.org/static/img/favicon.png";

        _urlTemplate = "https://oadoi.org/{z:DOI}";
        _urlParams = [ ];

        _urlNamespaces = {
          "" = "http://a9.com/-/spec/opensearch/1.1/";
          z = "http://www.zotero.org/namespaces/openSearch#";
          rft = "info:ofi/fmt:kev:mtx:journal";
        };
      }
    ];
  };

  systemd.user.services.zotero = {
    Unit = {
      Description = pkgs.zotero.meta.description;
      PartOf = [ "graphical-session.target" ];
      After = [ "picom.service" "tray.target" ];
    };
    Install.WantedBy = [ "graphical-session.target" ];

    Service = {
      Type = "simple";
      ExecStart = lib.getExe config.programs.zotero.package;
      ExecStartPost = lib.singleton ''
        ${pkgs.xdotool}/bin/xdotool \
            search \
                --class --classname --role --all \
                --limit 1 \
                --sync \
                '^Zotero$|^Navigator$|^browser$' \
            windowunmap --sync
      '';

      ExitType = "cgroup";
      Restart = "on-abnormal";
      SyslogIdentifier = "zotero";
    };
  };

  xsession.windowManager.bspwm.rules."Zotero:Navigator:*".locked = true;

  services.sxhkd.keybindings."super + z" = pkgs.writeShellScript "zotero" ''
    ${pkgs.systemd}/bin/systemctl start --user zotero.service
    bspwm-hide-unhide 'Navigator' 'Zotero' 'browser'
  '';

  xdg.mimeApps.defaultApplications = lib.genAttrs [
    "application/marc"
    "application/rdf+xml"
    "application/x-research-info-systems"
    "text/x-bibtex"
  ]
    (_: [ "zotero.desktop" ])
  ;

  programs.qutebrowser = {
    aliases.zotero = "spawn -u ${qutebrowser-zotero}/bin/qute-zotero";
    aliases.Zotero = "hint links userscript ${qutebrowser-zotero}/bin/qute-zotero";
    keyBindings.normal = let open = x: "open -rt ${x}"; in {
      "zpz" = "zotero";
      "zpZ" = "Zotero";
      "rz" = open "${proxy}?qurl={url}";
    };

    searchEngines = {
      "!library" = "${proxy}?qurl=http%3A%2F%2Fsearch.ebscohost.com%2Flogin.aspx%3Fdirect%3Dtrue%26site%3Deds-live%26scope%3Dsite%26group%3Dmain%26profile%3Deds%26authtime%3Dcookie%2Cip%2Cuid%26bQuery%3D{quoted}";
      "!scholar" = "${proxy}?qurl=https%3A%2F%2Fscholar.google.com%2Fscholar%3Fhl%3Den%26q%3D{quoted}%26btnG%3DSearch";
    };
  };

  # TODO this should work, but it sure don't
  # services.xsuspender.rules.zotero = {
  #   matchWmClassGroupContains = "Zotero";
  #   downclockOnBattery = 0;
  #   suspendDelay = 15;
  #   resumeEvery = 60;
  #   resumeFor = 5;

  #   # Only suspend if LibreOffice isn't currently open, and qutebrowser isn't
  #   # currently visible, since it would cause the connector to wait until it is
  #   # momentarily unsuspended, which is annoying

  #   execSuspend = builtins.toString (pkgs.writeShellScript "suspend" ''
  #     ! ${pkgs.xdotool}/bin/xdotool search \
  #         --limit 1 \
  #         --classname \
  #         '^libreoffice.*' \
  #         >/dev/null \
  #     || ! ${pkgs.xdotool}/bin/xdotool search \
  #         --limit 1 \
  #         --classname \
  #         --onlyvisible \
  #         '^qutebrowser$' \
  #         >/dev/null
  #   '');
  # };
}

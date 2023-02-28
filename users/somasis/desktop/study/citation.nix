{ pkgs
, config
, lib
, ...
}:
let
  # TODO I'm not sure how to package this correctly
  # Traceback (most recent call last):
  #   File "/nix/store/q258ir6s45m6nsrg8k8aipcrxmsy53d0-python3.10-qute-zotero-unstable-2019-06-15/share/qutebrowser/userscripts/zotero", line 22, in <module>
  #       from requests import post, get, ReadTimeout, ConnectionError
  #       ModuleNotFoundError: No module named 'requests'
  qute-zotero = pkgs.callPackage
    ({ lib, fetchFromGitLab, python3Packages }:
      python3Packages.buildPythonPackage rec {
        pname = "qute-zotero";
        version = "unstable-2019-06-15";

        format = "other";

        src = pkgs.fetchFromGitHub {
          owner = "parchd-1";
          repo = "qutebrowser-zotero";
          rev = "54706b43433c3ea8da6b7b410d67528da9779657";
          hash = "sha256-Jv5qrpWSMrfGr6gV8PxELCOfZ0PyGBPO+nBt2czYuu4=";
        };

        doConfigure = false;
        doBuild = false;

        propagatedBuildInputs = [ python3Packages.requests ];

        installPhase = ''
          install -m0755 -D $src/qute-zotero $out/share/qutebrowser/userscripts/zotero
        '';

        postInstall = ''
          buildPythonPath "$out $propagatedBuildInputs"
          patchPythonScript "$out/share/qutebrowser/userscripts/zotero"
        '';

        meta = with lib; {
          description = ''Connect qutebrowser to a running Zotero instance'';
          homepage = "https://github.com/parchd-1/qutebrowser-zotero";
          maintainers = with maintainers; [ somasis ];
          license = licenses.gpl3;
        };
      })
    { };

  qute-zotero' = "${qute-zotero}/share/qutebrowser/userscripts/zotero";
in
{
  programs.zotero = {
    enable = true;

    package = pkgs.symlinkJoin {
      name = "zotero-final";

      buildInputs = [ pkgs.makeWrapper ];
      paths = [ pkgs.zotero ];

      # Ensure that there isn't a mismatch between extension settings
      # (which could get modified during runtime, and then be written
      # to prefs.js by Zotero) and our user.js.
      postBuild =
        let
          prefs = "${config.programs.zotero.profiles.default.path}/zotero/prefs.js";

          managedPrefs = lib.concatStringsSep " " (map (x: "-e 'user_pref(\"${x}\", '") (builtins.attrNames config.programs.zotero.profiles.default.settings));

          filterPrefs = pkgs.writeShellScript "filter-prefs" ''
            export PATH="${lib.makeBinPath [ pkgs.coreutils pkgs.gnugrep pkgs.moreutils ]}:$PATH"

            touch "${prefs}"
            grep -vF ${managedPrefs} "${prefs}" | sponge "${prefs}"
          '';
        in
        ''
          wrapProgram $out/bin/zotero --run "${filterPrefs}"
        '';
    };

    profiles.default = {
      path = "${config.xdg.configHome}/zotero";

      settings =
        let
          # Chicago Manual of Style 17th edition (full note)
          style = "http://www.zotero.org/styles/chicago-fullnote-bibliography";
          locale = "en-US";
        in
        rec
        {
          "intl.locale.requested" = locale;

          # Use Appalachian State University's OpenURL resolver
          "extensions.zotero.openURL.resolver" = "https://login.proxy006.nclive.org/login?url=https://resolver.ebscohost.com/openurl?";

          # Sort settings
          "extensions.zotero.sortAttachmentsChronologically" = true;
          "extensions.zotero.sortNotesChronologically" = true;

          # Citation settings
          "extensions.zotero.export.citePaperJournalArticleURL" = true;

          "extensions.zotero.export.lastStyle" = style;
          "extensions.zotero.export.quickCopy.locale" = locale;
          "extensions.zotero.export.quickCopy.setting" = "bibliography=${style}";

          # Attachment settings
          "extensions.zotero.useDataDir" = true;
          "extensions.zotero.dataDir" = "${config.home.homeDirectory}/study/zotero";
          "extensions.zotfile.dest_dir" = "${config.home.homeDirectory}/study/doc"; # ZotFile > General Settings > "Location of Files"
          "extensions.zotfile.source_dir" = "${config.home.homeDirectory}/mess/current/incoming"; # ZotFile > General Settings > "Source Folder for Attaching New Files"
          "extensions.zotfile.useZoteroToRename" = false; # ZotFile > Renaming Rules > "Use Zotero to Rename";

          # ZotFile > Renaming Rules > "Format for all Item Types except Patents"
          # [author(s) - ]title[ (volume)][ ([year][, book title/journal/publisher/meeting])]
          "extensions.zotfile.renameFormat" = "{%a - }%t{ (%v)}{ (%y{, %B|, %w})}";

          # Custom wildcards
          "extensions.zotfile.wildcards.user" = builtins.toString (builtins.toJSON {
            # For book sections.
            "B" = "bookTitle";
          });

          "extensions.zotfile.authors_delimiter" = ", "; # ZotFile > Renaming Rules > "Delimiter between multiple authors"
          "extensions.zotfile.max_authors" = 2; # ZotFile > Renaming Rules > "Maximum number of authors"
          "extensions.zotero.attachmentRenameFormatString" = "{%c - }%t{100}{ (%y)}"; # Set the file name format used by Zotero's internal stuff

          "extensions.zotfile.import" = false; # ZotFile > Location of Files > Custom Location
          "extensions.zotero.autoRenameFiles.linked" = true; # ZotFile > General Settings > Location of Files > Custom Location

          # ZotFile > Advanced Settings > "Only work with the following filetypes"
          "extensions.zotfile.filetypes" = lib.concatStringsSep "," [ "pdf" "epub" "docx" "odt" ];

          "extensions.zotero.autoRenameFiles.fileTypes" = lib.concatStringsSep "," [
            "application/pdf"
            "application/epub+zip"
            "application/vnd.openxmlformats-officedocument.wordprocessingml.document"
            "application/vnd.oasis.opendocument.text"
          ];

          "extensions.zotfile.confirmation" = false; # ZotFile > Advanced Settings > "Ask user when attaching new files"
          "extensions.zotfile.confirmation_batch_ask" = false; # ZotFile > Advanced Settings > "Ask user to (batch) rename or move [0] or more attachments
          "extensions.zotfile.confirmation_batch" = 0;
          "extensions.zotfile.automatic_renaming" = 2; # ZotFile > Advanced Settigns > "Automatically rename new attachments" > "Always ask (non-disruptive)"

          "extensions.zotfile.removeDiacritics" = true; # ZotFile > Advanced Settings > "Remove special characters (diacritics) from filename"

          # Zotero AutoIndex
          "extensions.zotero.fulltext.pdfMaxPages" = 1024;

          # Zotero OCR
          "extensions.zotero.zoteroocr.ocrPath" = "${pkgs.tesseract5}/bin/tesseract";
          "extensions.zotero.zoteroocr.pdftoppmPath" = "${pkgs.poppler_utils}/bin/pdftoppm";

          "extensions.zotero.zoteroocr.outputPDF" = true; # Output options > "Save output as a PDF with text layer"
          "extensions.zotero.zoteroocr.overwritePDF" = true; # Output options > "Save output as a PDF with text layer" > "Overwrite the initial PDF with the output"

          "extensions.zotero.zoteroocr.outputHocr" = false; # Output options > "Save output as a HTML/hocr file(s)"
          "extensions.zotero.zoteroocr.outputNote" = false; # Output options > "Save output as a note"
          "extensions.zotero.zoteroocr.outputPNG" = false; # Output options > "Save the intermediate PNGs as well in the folder"

          # Zotero PDF Preview
          "extensions.zotero.pdfpreview.previewTabName" = "PDF Preview"; # Default tab name clashes with Zotero Citation Preview

          # Zotero Citation Preview
          "extensions.zoteropreview.citationstyle" = style;

          # Zotero LibreOffice Integration
          "extensions.zotero.integration.useClassicAddCitationDialog" = true;
        };
    };
  };

  home.persistence."/persist${config.home.homeDirectory}".directories = [{
    # NOTE Can't use symlink for ~/etc/zotero; user.js is stored in there,
    #      and so home-manager will complain while building; using bindfs really
    #      just hides the problem.
    # method = "symlink";
    directory = "etc/zotero";
  }];

  # Install the Zotero connector
  systemd.user.services.libreoffice.Service.ExecStartPre = [
    "${pkgs.libreoffice}/bin/unopkg add -f ${config.programs.zotero.package}/usr/lib/zotero-bin-${pkgs.zotero.version}/extensions/zoteroOpenOfficeIntegration@zotero.org/install/Zotero_OpenOffice_Integration.oxt"
  ];

  programs.qutebrowser.keyBindings.normal = {
    "<z><p><z>" = "spawn -u ${qute-zotero'}";
    "<z><p><Z>" = "hint links userscript ${qute-zotero'}";
  };
}

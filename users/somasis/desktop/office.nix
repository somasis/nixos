{ pkgs
, config
, lib
, ...
}:
let
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

        propagatedBuildInputs = with python3Packages; [ requests ];

        installPhase = ''
          install -m0755 -D $src/qute-zotero $out/share/qutebrowser/userscripts/zotero
        '';

        postInstall = ''
          wrapPythonProgramsIn "$out/share/qutebrowser/userscripts/zotero" "$out $propagatedBuildInputs"
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

  mkUserJs = prefs:
    ''
      ${lib.concatStrings (lib.mapAttrsToList (name: value: ''
        user_pref("${name}", ${builtins.toJSON value});
      '') prefs)}
    '';
in
{
  # TODO: libreoffice needs to use the extension from the zotero install
  home.packages = [
    pkgs.libreoffice

    pkgs.zotero
    pkgs.tesseract # zotero-ocr
    pkgs.poppler_utils # zotero-ocr
  ];

  # See for more details:
  # <https://wiki.documentfoundation.org/UserProfile#User_profile_content>
  home.persistence."/persist${config.home.homeDirectory}".directories = [
    "etc/libreoffice"

    ".zotero"
  ];

  home.file.".zotero/zotero/31kqtkbz.default/user.js".text = mkUserJs rec {
    # Use Canadian English for the locale so that I can have ISO dates in the browser.
    "intl.locale.requested" = "en-CA";

    # Use Appalachian State University resolver
    "extensions.zotero.openURL.resolver" = "https://login.proxy006.nclive.org/login?url=https://resolver.ebscohost.com/openurl?";

    # Sort settings
    "extensions.zotero.sortAttachmentsChronologically" = true;
    "extensions.zotero.sortNotesChronologically" = true;

    # Citation settings
    "extensions.zotero.export.citePaperJournalArticleURL" = true;

    # Chicago Manual of Style 17th edition (full note)
    "extensions.zotero.export.lastStyle" = "http://www.zotero.org/styles/chicago-fullnote-bibliography";

    # Attachment settings
    "extensions.zotero.useDataDir" = true;
    "extensions.zotero.dataDir" = "${config.home.homeDirectory}/study/zotero";
    "extensions.zotfile.dest_dir" = "${config.home.homeDirectory}/study/doc"; # ZotFile > General Settings > "Location of Files"
    "extensions.zotfile.source_dir" = "${config.home.homeDirectory}/mess/current/incoming"; # ZotFile > General Settings > "Source Folder for Attaching New Files"
    "extensions.zotfile.useZoteroToRename" = false; # ZotFile > Renaming Rules > "Use Zotero to Rename";
    "extensions.zotfile.renameFormat" = "{%a - }{%t}{ (%y{, %j|, %p})}"; # ZotFile > Renaming Rules > "Format for all Item Types except Patents"
    "extensions.zotfile.authors_delimiter" = ", "; # ZotFile > Renaming Rules > "Delimiter between multiple authors"
    "extensions.zotero.attachmentRenameFormatString" = "{%c - }%t{100}{ (%y)}"; # Set the file name format used by Zotero's internal stuff

    "extensions.zotfile.import" = false; # ZotFile > Location of Files > Custom Location
    "extensions.zotero.autoRenameFiles.linked" = true; # ZotFile > General Settings > Location of Files > Custom Location
    "extensions.zotero.autoRenameFiles.fileTypes" = "application/pdf,application/vnd.openxmlformats-officedocument.wordprocessingml.document,application/vnd.oasis.opendocument.text,text/plain,application/epub+zip";

    "extensions.zotfile.confirmation" = false; # ZotFile > Advanced Settings > "Ask user when attaching new files"
    "extensions.zotfile.confirmation_batch" = 1; # ZotFile > Advanced Settings > "Ask user to (batch) rename or move 2 or more attachments

    "extensions.zotfile.removeDiacritics" = true; # ZotFile > Advanced Settings > "Remove special characters (diacritics) from filename"

    # Zotero AutoIndex
    "extensions.zotero.fulltext.pdfMaxPages" = 1024;

    # Zotero OCR
    "extensions.zotero.zoteroocr.ocrPath" = "${pkgs.tesseract}/bin/tesseract";
    "extensions.zotero.zoteroocr.pdftoppmPath" = "${pkgs.poppler_utils}/bin/pdftoppm";
    "extensions.zotero.zoteroocr.outputHocr" = false; # Output options > "Save output as a HTML/hocr file(s)"
    "extensions.zotero.zoteroocr.outputNote" = false; # Output options > "Save output as a note"
    "extensions.zotero.zoteroocr.outputPNG" = false; # Output options > "Save the intermediate PNGs as well in the folder"

    # Zotero PDF Preview
    "extensions.zotero.pdfpreview.previewTabName" = "PDF Preview"; # Default tab name clashes with Zotero Citation Preview

    # Zotero Citation Preview
    "extensions.zoteropreview.citationstyle" = "${"extensions.zotero.export.lastStyle"}";

    # Zotero LibreOffice Integration
    "extensions.zotero.integration.useClassicAddCitationDialog" = true;
  };

  services.xsuspender.rules = {
    zotero = {
      matchWmClassGroupContains = "Zotero";
      downclockOnBattery = 1;
      suspendDelay = 15;
      resumeEvery = 60;
      resumeFor = 5;
      # suspendSubtreePattern = ".";
    };
  };

  programs.qutebrowser.keyBindings.normal = {
    "<z><p><z>" = "spawn -u ${qute-zotero'}";
    "<z><p><Z>" = "hint links userscript ${qute-zotero'}";
  };

  systemd.user.services.libreoffice = {
    Unit = {
      Description = pkgs.libreoffice.meta.description;
      PartOf = [ "graphical-session.target" ];
    };
    Install.WantedBy = [ "graphical-session.target" ];

    Service = {
      Type = "simple";
      ExecStartPre = [
        # Wait for any standalone instances of libreoffice to quit; there might be one open,
        # which will cause ExecStart to fail if we don't wait for it to end by itself.
        # We especially do not want to kill it since it might be some in-progress writing.
        # If there is no process matching the pattern, pwait will exit non-zero.
        ''-${pkgs.procps}/bin/pwait -u ${config.home.username} "soffice.bin"''

        # Install the Zotero connector
        "${pkgs.libreoffice}/bin/unopkg add -f ${pkgs.zotero}/usr/lib/zotero-bin-${pkgs.zotero.version}/extensions/zoteroOpenOfficeIntegration@zotero.org/install/Zotero_OpenOffice_Integration.oxt"
      ];
      ExecStart = [
        "${pkgs.libreoffice}/bin/libreoffice --quickstart --nologo --nodefault"
      ];
      Restart = "on-success";
    };
  };
}

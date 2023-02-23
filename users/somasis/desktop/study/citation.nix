{ pkgs
, config
, lib
, ...
}:
let
  inherit (pkgs) zotero;
  zotero' = pkgs.symlinkJoin {
    name = "zotero-final";

    buildInputs = [ pkgs.makeWrapper ];
    paths = [ zotero ];

    # Ensure that there isn't a mismatch between extension settings
    # (which could get modified during runtime, and then be written
    # to prefs.js by Zotero) and our user.js.
    postBuild =
      let
        prefs = "$HOME/.zotero/zotero/home-manager.managed/prefs.js";

        filterPrefs = pkgs.writeShellScript "filter-prefs" ''
          export PATH="${lib.makeBinPath [ pkgs.gnugrep pkgs.coreutils ]}:$PATH"

          touch "${prefs}"

          prefsFiltered=$(
              grep -v \
                  -e '^user_pref("extensions\.zotero.autoRenameFiiles' \
                  -e '^user_pref("extensions\.zotero.fulltext' \
                  -e '^user_pref("extensions\.zotero.pdfpreview' \
                  -e '^user_pref("extensions\.zotero.zoteroocr' \
                  -e '^user_pref("extensions\.zoteropreview' \
                  "${prefs}"
          )

          prefsFiltered=$(grep -vP '^user_pref\("extensions\.zotfile\.(?!version)' <<<"$prefs")

          cat > "${prefs}" <<< "$prefsFiltered"
        '';
      in
      ''
        wrapProgram $out/bin/zotero --run "${filterPrefs}"
      '';
  };

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

  # Taken from home-manager
  # <home-manager/modules/programs/firefox.nix>
  mkUserJs = prefs:
    ''
      ${lib.concatStrings (lib.mapAttrsToList (name: value: ''
        user_pref("${name}", ${builtins.toJSON value});
      '') prefs)}
    '';
in
{
  home.packages = [ zotero' ];

  home = {
    persistence."/persist${config.home.homeDirectory}".directories = [{
      # NOTE Can't use symlink for ~/etc/zotero; user.js is stored in there,
      #      and so home-manager will complain while building; using bindfs really
      #      just hides the problem.
      # method = "symlink";
      directory = "etc/zotero";
    }];

    # HACK Force Zotero to use XDG directories, with a ~/.zotero/zotero symlink
    file = {
      ".zotero/zotero/home-manager.managed".source = config.lib.file.mkOutOfStoreSymlink "${config.xdg.configHome}/zotero";
      ".zotero/zotero/profiles.ini".text = lib.generators.toINI { } {
        General.StartWithLastProfile = 1;
        Profile0 = {
          Name = "default";
          IsRelative = 0;
          Path = "${config.xdg.configHome}/zotero";
          Default = 1;
        };
      };
    };
  };

  xdg.configFile = {
    # Keep ".zotero/zotero/home-manager.managed/prefs.js" unmanaged;
    # Zotero store runtime data there.
    "zotero/user.js".text =
      let
        # Chicago Manual of Style 17th edition (full note)
        style = "http://www.zotero.org/styles/chicago-fullnote-bibliography";
        locale = "en-US";
      in
      mkUserJs rec {
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

        # Attachment settings
        "extensions.zotero.useDataDir" = true;
        "extensions.zotero.dataDir" = "${config.home.homeDirectory}/study/zotero";
        "extensions.zotfile.dest_dir" = "${config.home.homeDirectory}/study/doc"; # ZotFile > General Settings > "Location of Files"
        "extensions.zotfile.source_dir" = "${config.home.homeDirectory}/mess/current/incoming"; # ZotFile > General Settings > "Source Folder for Attaching New Files"
        "extensions.zotfile.useZoteroToRename" = false; # ZotFile > Renaming Rules > "Use Zotero to Rename";

        # ZotFile > Renaming Rules > "Format for all Item Types except Patents"
        # [author(s) - ]title[ (volume)][ ([year][, journal|publisher])]
        "extensions.zotfile.renameFormat" = "{%a - }{%t}{ (%v)}{ ({%y{, {%j| %p}}}}";

        "extensions.zotfile.authors_delimiter" = ", "; # ZotFile > Renaming Rules > "Delimiter between multiple authors"
        "extensions.zotero.attachmentRenameFormatString" = "{%c - }%t{100}{ (%y)}"; # Set the file name format used by Zotero's internal stuff

        "extensions.zotfile.import" = false; # ZotFile > Location of Files > Custom Location
        "extensions.zotero.autoRenameFiles.linked" = true; # ZotFile > General Settings > Location of Files > Custom Location

        "extensions.zotfile.filetypes" = "pdf,epub,docx,odt"; # ZotFile > Advanced Settings > "Only work with the following filetypes"
        "extensions.zotero.autoRenameFiles.fileTypes" = "application/pdf,application/epub+zip,application/vnd.openxmlformats-officedocument.wordprocessingml.document,application/vnd.oasis.opendocument.text";

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

  # Install the Zotero connector
  systemd.user.services.libreoffice.Service.ExecStartPre = [
    "${pkgs.libreoffice}/bin/unopkg add -f ${zotero'}/usr/lib/zotero-bin-${zotero.version}/extensions/zoteroOpenOfficeIntegration@zotero.org/install/Zotero_OpenOffice_Integration.oxt"
  ];

  programs.qutebrowser.keyBindings.normal = {
    "<z><p><z>" = "spawn -u ${qute-zotero'}";
    "<z><p><Z>" = "hint links userscript ${qute-zotero'}";
  };
}

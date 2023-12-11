final: prev:
let
  inherit (prev) lib callPackage;

  buildZoteroXpiAddon = prev.makeOverridable (
    { stdenv ? prev.stdenv
    , fetchurl ? prev.fetchurl
    , pname
    , version
    , addonId
    , url
    , hash
    , meta
    , ...
    }:
    stdenv.mkDerivation {
      name = "${pname}-${version}";

      inherit meta;

      src = fetchurl { inherit url hash; };

      preferLocalBuild = true;
      allowSubstitutes = true;

      buildCommand = ''
        dst="$out/share/zotero/extensions/{ec8030f7-c20a-464f-9b0e-13a3a9e97384}"
        mkdir -p "$dst"
        install -v -m644 "$src" "$dst/${addonId}.xpi"
      '';
    }
  );
in
{
  zotero-open-pdf = buildZoteroXpiAddon rec {
    pname = "zotero-open-pdf";
    version = "0.0.8";
    addonId = "open-pdf@iris-advies.com";

    url = "https://github.com/retorquere/zotero-open-pdf/releases/download/v${version}/zotero-open-pdf-${version}.xpi";
    hash = "sha256-ohQmaDwiFAIAckyRRsL432bRYtcIRydWQtWc3/99uvo=";

    meta = with lib; {
      homepage = "https://github.com/retorquere/zotero-open-pdf";
      # license unclear
      platforms = platforms.all;
    };
  };

  cita = buildZoteroXpiAddon rec {
    pname = "cita";
    version = "0.5.5";
    addonId = "zotero-wikicite@wikidata.org";

    url = "https://github.com/diegodlh/zotero-cita/releases/download/v${version}/zotero-cita-v${version}.xpi";
    hash = "sha256-8L7wUABOMXoQ+irGZtcgpZu8cXHYLFR7UgCGKRmlJmQ=";

    meta = with lib; {
      homepage = "https://github.com/diegodlh/zotero-cita";
      license = [ licenses.gpl3 ];
      platforms = platforms.all;
    };
  };

  zotero-storage-scanner = buildZoteroXpiAddon rec {
    pname = "zotero-storage-scanner";
    version = "5.0.12";
    addonId = "storage-scanner@iris-advies.com";

    url = "https://github.com/retorquere/zotero-storage-scanner/releases/download/v${version}/zotero-storage-scanner-${version}.xpi";
    hash = "sha256-WGF3//sdZ8qk9IKOrgP7kbi7Yz5iRMXCbr2wQeXqpT8=";

    meta = with lib; {
      homepage = "https://github.com/retorquere/zotero-storage-scanner";
      # license unclear
      platforms = platforms.all;
    };
  };

  zotero-auto-index = buildZoteroXpiAddon rec {
    pname = "zotero-auto-index";
    version = "5.0.9";
    addonId = "auto-index@iris-advies.com";

    url = "https://github.com/retorquere/zotero-auto-index/releases/download/v${version}/zotero-auto-index-${version}.xpi";
    hash = "sha256-VmOZn+6g0KLCxkLafc+5DaTP9/Fvx32a9LUBD6NQ8MI=";

    meta = with lib; {
      homepage = "https://github.com/retorquere/zotero-auto-index";
      # TODO license
      platforms = platforms.all;
    };
  };

  zotero-ocr = buildZoteroXpiAddon rec {
    pname = "zotero-ocr";
    version = "0.6.0";
    addonId = "zotero-ocr@bib.uni-mannheim.de";

    url = "https://github.com/UB-Mannheim/zotero-ocr/releases/download/${version}/zotero-ocr-${version}.xpi";
    hash = "sha256-rYx0GMmiVbnxCPHHu32YM9yNqOPnQcyMw5QD6r0apwk=";

    meta = with lib; {
      homepage = "https://github.com/UB-Mannheim/zotero-ocr";
      # TODO license
      platforms = platforms.all;
    };
  };

  zotero-robustlinks = buildZoteroXpiAddon rec {
    pname = "zotero-robustlinks";
    version = "2.0.0-20220320145937";
    addonId = "zotero-robustlinks@mementoweb.org";

    url = "https://github.com/lanl/Zotero-Robust-Links-Extension/releases/download/v${version}/robustlinks.xpi";
    hash = "sha256-U4ZPhFP06YP8xXmx8p0lTUa0nDtZN3YyrCPxtgz7D0E=";

    meta = with lib; {
      homepage = "https://robustlinks.mementoweb.org/zotero/";
      # TODO license
      platforms = platforms.all;
    };
  };

  zotero-abstract-cleaner = buildZoteroXpiAddon rec {
    pname = "zotero-abstract-cleaner";
    version = "0.1.6";
    addonId = "ZoteroAbstractCleaner@carter-tod.com";

    url = "https://github.com/dcartertod/zotero-plugins/releases/download/${version}/ZoteroAbstractCleaner.xpi";
    hash = "sha256-6ankwlieLLHiUPwhXptWwyomUaKCwEbVebTOWSbrLWs=";

    meta = with lib; {
      homepage = "https://github.com/dcartertod/zotero-plugins/tree/main/ZoteroAbstractCleaner";
      # TODO license
      platforms = platforms.all;
    };
  };

  zotero-preview = buildZoteroXpiAddon rec {
    pname = "zotero-preview";
    version = "0.1.6";
    addonId = "zoteropreview@carter-tod.com";

    url = "https://github.com/dcartertod/zotero-plugins/releases/download/${version}/ZoteroPreview.xpi";
    hash = "sha256-Ybe6Ot+eWVQEjQn6SohJdU2a64mcw1hl92blKi9JqXM=";

    meta = with lib; {
      homepage = "https://github.com/dcartertod/zotero-plugins/tree/main/ZoteroPreview";
      # TODO license
      platforms = platforms.all;
    };
  };

  zotfile = buildZoteroXpiAddon rec {
    pname = "zotfile";
    version = "5.1.2";
    addonId = "zotfile@columbia.edu";

    url = "https://github.com/jlegewie/zotfile/releases/download/v${version}/zotfile-${version}-fx.xpi";
    hash = "sha256-vmJVLqNgxbI6eE3TqDKJs/u/Bdemag2aADfy8L89YKc=";

    meta = with lib; {
      homepage = "https://github.com/jlegewie/zotfile";
      license = [ licenses.gpl3 ];
      platforms = platforms.all;
    };
  };
}

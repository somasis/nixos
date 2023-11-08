{ lib
, pkgs
, ...
}: {
  home.packages = [
    # PDF manipulation tools
    (pkgs.mupdf.override {
      # MuPDF with just the command line tools
      enableX11 = false;
      enableCurl = false;
      enableGL = false;
    })

    # PDF editing tools
    pkgs.ocrmypdf
    pkgs.pdfarranger

    # Scan editing tools
    pkgs.deskew
    pkgs.scantailor-advanced

    pkgs.pdfgrep
  ];

  xdg.configFile = {
    "pdfarranger/config.ini".text = lib.generators.toINI
      {
        mkKeyValue = k: v:
          if builtins.isBool v then
            lib.generators.mkKeyValueDefault { } "=" k (if v then "True" else "False")
          else
            lib.generators.mkKeyValueDefault { } "=" k v
        ;
      }
      {
        preferences = {
          content-loss-warning = true;
        };
      }
    ;

    "scantailor-advanced/scantailor-advanced.ini".text = lib.generators.toINI { } {
      settings = {
        auto_save_project = true;
        color_scheme = "native";
        enable_opengl = true;
        units = "in";
      };
    };
  };

  home.shellAliases = {
    pdfgrep = "pdfgrep --cache";
    ocr = "ocrmypdf --deskew --clean";
  };

  cache.directories = [ "var/cache/pdfgrep" ];
}

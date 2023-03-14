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

    pkgs.ocrmypdf
    pkgs.pdfarranger

    # Scan editing tools
    pkgs.deskew
    pkgs.scantailor-advanced
  ];

  xdg.configFile."scantailor-advanced/scantailor-advanced.ini".text = lib.generators.toINI { } {
    settings = {
      auto_save_project = true;
      color_scheme = "native";
      enable_opengl = true;
      units = "in";
    };
  };
}

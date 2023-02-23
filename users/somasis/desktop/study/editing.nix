{ pkgs, ... }: {
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
}

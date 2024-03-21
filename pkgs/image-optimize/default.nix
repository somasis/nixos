{ lib
, writeShellApplication

, coreutils
, file
, gnugrep
, oxipng
, optipng
, jpegoptim
}:
writeShellApplication {
  name = "image-optimize";

  runtimeInputs = [
    coreutils
    file
    gnugrep

    oxipng
    optipng
    jpegoptim
  ];

  text = builtins.readFile ./image-optimize.bash;

  meta = with lib; {
    description = "Losslessly optimize an image file";
    license = licenses.unlicense;
    maintainers = with maintainers; [ somasis ];
    mainProgram = "image-optimize";
  };
}

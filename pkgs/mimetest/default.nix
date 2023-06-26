{ lib
, file
, stdenv
}:
stdenv.mkDerivation {
  pname = "mimetest";
  version = "0.1";

  src = ./.;

  buildInputs = [ file.dev ];

  buildPhase = ''
    $CC -std=c99 -Wall -pedantic \
        -lmagic \
        "$src/mimetest.c" \
        -o "mimetest"
  '';

  installPhase = ''
    mkdir -p "$out/bin"
    mkdir -p "$out/share/man/man1"

    install -m0755 mimetest   "$out/bin/mimetest"
    install -m0644 mimetest.1 "$out/share/man/man1/mimetest"
  '';

  meta = with lib; {
    description = "Test files against MIME types";
    license = licenses.unlicense;
    maintainers = with maintainers; [ somasis ];
  };
}

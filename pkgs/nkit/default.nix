{ lib
, , fetchzip

, gnused
, makeWrapper

, mono
}:
stdenv.mkDerivation {
  pname = "nkit";
  version = "1.4";

  src = fetchzip {
    url = "https://gbatemp.net/download/nkit.36157/download";
    hash = "sha256-5gCwotus94R3nOM7ASWfGXxfjPxxNfGDEWDT+Yu0McY=";
  };

  nativeBuildInputs = [ gnused makeWrapper ];
  runtimeInputs = [ mono ];

  installPhase = ''
    runHook preInstall

    target="$out/lib/dotnet/${pname}"
    install -d "$target" "$out/share/doc" "$out/bin"

    cp -vr $src/* "$target"

    (
        cd "$target"
        for exe in *.exe; do
            chmod +x "$exe"

            name=$(
                sed -E \
                    -e 's/\.exe$//' \
                    -e 's/[A-Z][A-Z]+/-\L&/' \
                    -e 's/([A-Z][a-z])/-\L\1/g' \
                    -e 's/^-+//' \
                    <<<"$name"
            )
            name=nkit-"$name"

            makeWrapper "${mono}/bin/mono" "$out/bin/$name" \
                --add-flags "$target/$exe" \
                --prefix MONO_PATH : "$target/lib" \
                --prefix LD_LIBRARY_PATH : "$target/lib" \
        done
    )

    substituteInPlace "NKit.dll.config" \
       # uhhhh

    runHook postInstall
  '';

  meta = with lib; {
    description = "
    homepage = " https://wiki.gbatemp.net/wiki/NKit ";
      sourceProvenance = "
      binaryBytecode ";
    inherit (mono.meta) platforms;
  };
}

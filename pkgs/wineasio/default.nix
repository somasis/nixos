{ lib
, multiStdenv
, fetchzip
, pkgs
, pkgsi686Linux
,
}:
# TODO:
# - Wine should use ASIO for audio, see audio tab in winecfg.
#   To switch audio to ASIO edit registry HKEY_CURRENT_USER\Software\Wine\Drivers,
#   Add entry 'Audio=alsa'.
# - Wine can't find wineasio.dll.so, users need to put this in $wine/lib/wine
#   but users should not have to do this. Need to run wine64 regsvc32 wineasio.dll.so
let
  asiosdk = pkgs.callPackage ../asiosdk { };
  wine-wow = pkgs.wine.override { wineBuild = "wineWow"; };
in
multiStdenv.mkDerivation rec {
  pname = "wineasio";
  version = "1.1.0";

  src = fetchzip {
    url = "https://github.com/${pname}/${pname}/releases/download/v${version}/${pname}-${version}.tar.gz";
    sha256 = "sha256-IVgiGTrcs1c0NNMHIc0NElj3Hgd9RO+zrkAefQ26+AM=";
  };

  buildInputs = [
    wine-wow

    asiosdk
    pkgs.pkg-config
    pkgs.libjack2
    pkgsi686Linux.libjack2
  ];

  buildPhase = ''
    cp ${asiosdk}/common/asio.h .
    # cp asio.h asio.h.i686
    # chmod +w asio.h

    echo "build 64bit"
    export PREFIX=${wine-wow}
    export CFLAGS="$NIX_CFLAGS_COMPILE"
    ln -s ${wine-wow}/include/wine ./wine

    make -f Makefile.mk \
      build PREFIX=${wine-wow} ARCH=x86_64 M=64 LDFLAGS="$NIX_LDFLAGS"

    echo "build 32bit"
    rm wine
    ln -s ${wine-wow}/include/wine ./wine

    make -f Makefile.mk \
      build PREFIX=${wine-wow} ARCH=i386 M=32 LDFLAGS="$NIX_LDFLAGS"
  '';

  installPhase = ''
    ls -CFl
    ls -CFl build*

    # Install 64-bit drivers
    install -D -m755 build64/wineasio.dll    $out/lib/wine/x86_64-windows/wineasio.dll
    install -D -m755 build64/wineasio.dll.so $out/lib/wine/x86_64-unix/wineasio.dll.so

    # Install 32-bit drivers
    install -D -m755 build32/wineasio.dll    $out/lib/wine/i386-windows/wineasio.dll
    install -D -m755 build32/wineasio.dll.so $out/lib/wine/i386-unix/wineasio.dll.so
  '';

  meta = with lib; {
    description = "ASIO driver for WINE";
    license = licenses.lgpl21;
    maintainers = with maintainers; [ somasis ];
    homepage = "https://github.com/wineasio/wineasio";
  };
}

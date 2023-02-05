{ inputs, pkgs, lib, ... }:
let
  # These would be more correct, but they cause unnecessary rebuilds of the derivations
  # bfs = pkgs.bfs.overrideAttrs (finalAttrs: prevAttrs: {
  #   postInstall = ''
  #     ln -s bfs $out/bin/find
  #   '';
  # });

  # libarchive = pkgs.libarchive.overrideAttrs (finalAttrs: prevAttrs: {
  #   configureFlags = prevAttrs.configureFlags ++ [ "--enable-bsdtar" "--enable-bsdcpio" ];
  # });

  bfs = pkgs.symlinkJoin {
    name = "bfs";
    paths = [
      pkgs.bfs
      (pkgs.runCommandLocal "find" { } ''
        mkdir -p $out/bin
        ln -s ${pkgs.bfs}/bin/bfs $out/bin/find
      '')
    ];
  };

  libarchive = pkgs.symlinkJoin {
    name = "libarchive-utils";
    paths = [
      pkgs.libarchive
      (pkgs.runCommandLocal "bsdarchive" { } ''
        mkdir -p $out/bin
        ln -s ${pkgs.libarchive}/bin/bsdcpio $out/bin/cpio
        ln -s ${pkgs.libarchive}/bin/bsdtar $out/bin/tar
      '')
    ];
  };

  # TODO bugs :(
  # bsdunzip = (
  #   let
  #     year = builtins.substring 0 4 (inputs.bsdunzip.lastModifiedDate);
  #     month = builtins.substring 4 2 (inputs.bsdunzip.lastModifiedDate);
  #     day = builtins.substring 6 2 (inputs.bsdunzip.lastModifiedDate);
  #   in
  #   pkgs.stdenv.mkDerivation rec {
  #     pname = "bsdunzip";
  #     version = "unstable-${year}-${month}-${day}";

  #     src = inputs.bsdunzip;

  #     buildInputs = [ pkgs.libarchive ];
  #     nativeBuildInputs = [ pkgs.pkg-config ];

  #     makeFlags = [ "PREFIX=${placeholder "out"}" ];
  #     prepareFlags = [ "bsdunzip.c" "man" ];
  #     installFlags = [ "install" ];
  #     postInstall = ''
  #       ln -s bsdunzip $out/bin/unzip
  #     '';

  #     enableParallelBuilding = true;

  #     meta = with lib; {
  #       description = "libarchive(3)-utilizing unzip implementation, lightly ported from FreeBSD";
  #       license = [ licenses.isc licenses.bsd2 ];
  #       maintainers = with maintainers; [ somasis ];
  #     };
  #   }
  # );

  sbase = (
    let
      year = builtins.substring 0 4 (inputs.sbase.lastModifiedDate);
      month = builtins.substring 4 2 (inputs.sbase.lastModifiedDate);
      day = builtins.substring 6 2 (inputs.sbase.lastModifiedDate);
    in
    pkgs.stdenv.mkDerivation rec {
      pname = "sbase";
      version = "unstable-${year}-${month}-${day}";

      src = inputs.sbase;

      makeFlags = [ "PREFIX=${placeholder "out"}" ];
      buildFlags = [ "sbase-box" ];
      installFlags = [ "sbase-box-install" ];

      postInstall = ''
        rm \
            $out/bin/cksum  $out/share/man/man1/cksum.1 \
            $out/bin/find   $out/share/man/man1/find.1 \
            $out/bin/xargs  $out/share/man/man1/xargs.1 \
            $out/bin/sponge $out/share/man/man1/sponge.1
      '';

      enableParallelBuilding = true;

      meta = with lib; {
        description = "suckless Unix tools";
        license = licenses.mit;
        maintainers = with maintainers; [ somasis ];
      };
    }
  );

  ubase = (
    let
      year = builtins.substring 0 4 (inputs.ubase.lastModifiedDate);
      month = builtins.substring 4 2 (inputs.ubase.lastModifiedDate);
      day = builtins.substring 6 2 (inputs.ubase.lastModifiedDate);
    in

    pkgs.stdenv.mkDerivation rec {
      pname = "ubase";
      version = "unstable-${year}-${month}-${day}";

      src = inputs.ubase;

      postPatch = ''
        sed -i \
            -e '1i#include <sys/sysmacros.h>' \
            mountpoint.c stat.c libutil/tty.c
      '';

      makeFlags = [ "PREFIX=${placeholder "out"}" ];

      enableParallelBuilding = true;

      meta = with lib; {
        description = "suckless Linux base utils";
        license = licenses.mit;
        maintainers = with maintainers; [ somasis ];
      };
    }
  );

  busybox = (pkgs.busybox.override { enableStatic = true; });
  toybox = (pkgs.toybox.override { enableStatic = true; });
in
{
  home.packages = [
    bfs

    libarchive
    # bsdunzip

    # sbase
    # ubase

    # (pkgs.writeShellScriptBin ''sbase'' ''
    #   c="$1";
    #   exec $(PATH=${sbase}/bin:${ubase}/bin command -v "$c") "$@"
    # '')
  ];
}

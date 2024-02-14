{ config
, inputs
, pkgs
, lib
, ...
}:
let
  withLinks = package: links:
    # example:
    # withLinks pkgs.bfs [
    #   { to = "bin/bfs"; at = "bin/find"; }
    #   { to = "share/man/man1/bfs.1.gz"; at = "share/man/man1/find.1.gz"; }
    # ]
    pkgs.symlinkJoin {
      name = "${package.pname}-with-links";
      paths = [
        package
        (pkgs.runCommandLocal "links" { } (
          lib.concatLines (
            map
              (link: ''
                mkdir -p $out/${lib.escapeShellArg (builtins.dirOf link.at)}
                ln -s ${lib.escapeShellArg package}/${lib.escapeShellArg link.to} $out/${lib.escapeShellArg link.at}
              '')
              links
          )
        ))
      ];
    }
  ;

  sbase = pkgs.stdenv.mkDerivation rec {
    pname = "sbase";
    version = config.lib.somasis.flakeModifiedDateToVersion inputs.sbase;

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
  };

  ubase = pkgs.stdenv.mkDerivation rec {
    pname = "ubase";
    version = config.lib.somasis.flakeModifiedDateToVersion inputs.ubase;

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
  };
in
{
  home.packages = [
    (pkgs.busybox.override {
      enableStatic = true;

      # Otherwise the symlinks replace the coreutils in my environment.
      enableAppletSymlinks = false;
    })

    # (pkgs.toybox.override { enableStatic = true; })

    (withLinks pkgs.bfs [
      { to = "bin/bfs"; at = "bin/find"; }
      { to = "share/man/man1/bfs.1.gz"; at = "share/man/man1/find.1.gz"; }
    ])

    (withLinks pkgs.libarchive [
      { to = "bin/bsdcpio"; at = "bin/cpio"; }
      { to = "bin/bsdtar"; at = "bin/tar"; }
      { to = "share/man/man1/bsdcpio.1.gz"; at = "share/man/man1/cpio.1.gz"; }
      { to = "share/man/man1/bsdtar.1.gz"; at = "share/man/man1/tar.1.gz"; }
    ])

    # sbase
    # ubase

    # (pkgs.writeShellScriptBin "sbase" ''
    #   c="$1";
    #   exec $(PATH=${sbase}/bin:${ubase}/bin command -v "$c") "$@"
    # '')
  ];
}

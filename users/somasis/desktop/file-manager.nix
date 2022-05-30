{ pkgs, config, ... }: {
  home.packages = [
    # pkgs.pcmanfm
    pkgs.xfce.thunar-bare
    pkgs.xfce.tumbler
    pkgs.ffmpegthumbnailer

    (pkgs.writeShellScriptBin ''mount-archive'' ''
      set -e

      n=''${1%%.*}
      a=~/mnt/archive/"$n"

      mkdir -p "$a"
      ${pkgs.archivemount}/bin/archivemount -f -o auto_unmount "$1" "$a" &
      p=$!

      trap '${pkgs.fuse}/bin/fusermount -u "$a"' EXIT

      xdg-open "$a" &
      f=$!

      wait
    '')
  ];

  xdg.desktopEntries.mount-archive = {
    name = "Archive mounter";
    genericName = "ilo pi open poki";
    icon = "archive-manager";
    exec = "mount-archive %f";
    categories = [ "Utility" "Archiving" "Compression" ];
    mimeType = [
      "application/gzip"
      "application/warc"
      "application/x-7z-compressed"
      "application/x-archive"
      "application/x-bzip2"
      "application/x-cpio"
      "application/x-gtar"
      "application/x-lha"
      "application/x-lz4"
      "application/x-lzma"
      "application/x-lzop"
      "application/x-rar"
      "application/x-rpm"
      "application/x-tar"
      "application/x-xar"
      "application/x-xz"
      "application/zip"
      "application/zstd"
    ];
  };

  home.persistence."/persist${config.home.homeDirectory}".directories = [
    # "etc/pcmanfm"
    # "share/file-manager"
    "etc/Thunar"
  ];

  home.persistence."/cache${config.home.homeDirectory}".directories = [
    "var/cache/thumbnails"
  ];

  xdg.mimeApps.defaultApplications = {
    "inode/directory" = "thunar.desktop";
    "inode/mount-point" = "thunar.desktop";
  };
}

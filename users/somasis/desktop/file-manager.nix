{ lib
, pkgs
, config
, ...
}:
let
  inherit (lib)
    concatStringsSep
    escape
    mapAttrsToList
    ;

  inherit (config.lib.somasis)
    commaList
    ;

  thunar = pkgs.xfce.thunar-bare;
in
{
  home.packages = [
    thunar

    pkgs.xfce.tumbler
    pkgs.webp-pixbuf-loader # .webp
    pkgs.libgsf # .odf
    pkgs.nufraw-thumbnailer # .raw
    pkgs.gnome-epub-thumbnailer # .epub, .mobi

    pkgs.xfce.xfconf

    pkgs.ffmpegthumbnailer

    (pkgs.writeShellScriptBin "mount-archive" ''
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

  xfconf.settings.thunar =
    let
      listToCommaStringList = l: commaList (map builtins.toString l);
    in
    {
      # Display > View settings
      misc-folders-first = true; # Sort folders before files
      misc-file-size-binary = true; # Show file size in binary format

      # Display > Thumbnails
      misc-thumbnail-mode = "THUNAR_THUMBNAIL_MODE_ONLY_LOCAL"; # Local files only
      misc-thumbnail-max-file-size = 1048576 * 10; # Only show thumbnails for files smaller than 10MiB
      misc-thumbnail-draw-frames = true;

      # Display > Icon view
      misc-text-beside-icons = true;

      # Display > Window icon
      misc-change-window-icon = false;
      misc-full-path-in-window-title = true; # hidden

      # Display > Date
      misc-date-style = "THUNAR_DATE_STYLE_CUSTOM";
      misc-date-custom-style = "%Y-%m-%d %I:%M:%S %p";

      # Side pane > Image preview
      misc-image-preview-mode = "THUNAR_IMAGE_PREVIEW_MODE_STANDALONE";

      # Advanced > File transfer
      misc-parallel-copy-mode = "THUNAR_PARALLEL_COPY_MODE_ONLY_LOCAL"; # Transfer files in parallel
      misc-transfer-use-partial = "THUNAR_USE_PARTIAL_MODE_REMOTE"; # Use intermediate file on copy
      misc-transfer-verify-file = "THUNAR_VERIFY_FILE_MODE_ALWAYS"; # Verify file checksum on copy

      # Advanced > Search
      misc-recursive-search = "THUNAR_RECURSIVE_SEARCH_ALWAYS"; # Include subfolders

      # Advaned > Volume management
      misc-volume-management = false;

      # View defaults: default view
      default-view = "void"; # View new folders using "last active view"
      last-view = "ThunarCompactView";
      last-show-hidden = true;

      # View defaults: compact view
      last-compact-view-zoom-level = "THUNAR_ZOOM_LEVEL_50_PERCENT";

      # View defaults: details view
      last-details-view-zoom-level = "THUNAR_ZOOM_LEVEL_38_PERCENT";

      last-details-view-column-order = commaList [
        "THUNAR_COLUMN_NAME"
        "THUNAR_COLUMN_DATE_MODIFIED"
        "THUNAR_COLUMN_PERMISSIONS"
        "THUNAR_COLUMN_SIZE"
        "THUNAR_COLUMN_MIME_TYPE"

        "THUNAR_COLUMN_TYPE"
        "THUNAR_COLUMN_OWNER"
        "THUNAR_COLUMN_GROUP"
        "THUNAR_COLUMN_SIZE_IN_BYTES"
        "THUNAR_COLUMN_LOCATION"
        "THUNAR_COLUMN_DATE_CREATED"
        "THUNAR_COLUMN_DATE_ACCESSED"
        "THUNAR_COLUMN_RECENCY"
        "THUNAR_COLUMN_DATE_DELETED"
      ];
      last-details-view-visible-columns = commaList [
        "THUNAR_COLUMN_NAME"
        "THUNAR_COLUMN_DATE_MODIFIED"
        "THUNAR_COLUMN_PERMISSIONS"
        "THUNAR_COLUMN_SIZE"
        "THUNAR_COLUMN_MIME_TYPE"
      ];

      last-sort-column = "THUNAR_COLUMN_NAME";
      last-sort-order = "GTK_SORT_ASCENDING";
      misc-case-sensitive = true; # Use case sensitive sorting (hidden)

      last-details-view-fixed-columns = false; # Column sizing > Automatically expand columns as needed
      misc-folder-item-count = "THUNAR_FOLDER_ITEM_COUNT_ALWAYS"; # Column sizing > Size column of folders > Show number of containing items: Always

      # View defaults: icon view
      last-icon-view-zoom-level = "THUNAR_ZOOM_LEVEL_150_PERCENT";
      misc-highlighting-enabled = true; # Use different highlight style (hidden)

      last-location-bar = "ThunarLocationButtons"; # View > Location selector > Buttons style
      last-side-pane = "void"; # View > Side pane
      last-menubar-visible = false; # View > Menubar

      # Toolbar items
      last-toolbar-item-order = listToCommaStringList [
        14 # Location bar
        10 # Icon view
        11 # Details view
        12 # Compact view
        0 # Show menubar

        1
        2
        3
        4
        5
        6
        7
        8
        9
        15
        13
        16
        17
      ];
      last-toolbar-visible-buttons = listToCommaStringList [
        1 # Location bar
        1 # Icon view
        1 # Details view
        1 # Compact view
        0 # Show menubar

        0
        0
        0
        0
        0
        0
        0
        0
        0
        0
        0
        0
        0
      ];

      # Status bar information
      misc-status-bar-active-info = 31; # Size, Size in bytes, Filetype, Display name, Last modified
      misc-image-size-in-statusbar = true;

      misc-show-about-templates = false; # Don't show "about templates" dialog
    };

  # Use monospace in Thunar's details view
  gtk.gtk3.extraCss = ''
    window.thunar grid paned paned grid paned notebook scrolledwindow treeview {
      font: monospace;
      font-size: 10pt;
    }
  '';

  xdg.configFile = {
    "Thunar/uca.xml".text = ''
      <?xml version="1.0" encoding="UTF-8"?>
      <actions>
        <action>
          <icon>terminal</icon>
          <name>Open terminal here</name>
          <unique-id>1646950665388581-1</unique-id>
          <command>${pkgs.execline}/bin/execline-cd %f terminal</command>
          <description>Open a terminal in the selected or current directory</description>
          <patterns>*</patterns>
          <startup-notify/>
          <directories/>
        </action>
        <action>
          <icon>cs-backgrounds</icon>
          <name>Set as wallpaper</name>
          <unique-id>1646951605736596-2</unique-id>
          <command>wallpaperctl set -cover %f</command>
          <description>Set the selected image as the wallpaper</description>
          <patterns>*</patterns>
          <image-files/>
        </action>
      </actions>
    '';

    "Thunar/accels.scm".text = ''
      (gtk_accel_path "<Actions>/ThunarStandardView/invert-selection" "<Primary>i")
      (gtk_accel_path "<Actions>/ThunarStandardView/back-alt" "")
      (gtk_accel_path "<Actions>/ThunarActionManager/open-in-new-tab" "")
      (gtk_accel_path "<Actions>/ThunarWindow/switch-next-tab" "")
      (gtk_accel_path "<Actions>/ThunarStandardView/properties" "grave")
      (gtk_accel_path "<Actions>/ThunarStandardView/sort-by-mtime" "<Alt>4")
      (gtk_accel_path "<Actions>/ThunarStandardView/select-by-pattern" "<Primary>f")
      (gtk_accel_path "<Actions>/ThunarShortcutsPane/sendto-shortcuts" "")
      (gtk_accel_path "<Actions>/ThunarWindow/close-tab" "")
      (gtk_accel_path "<Actions>/ThunarWindow/view-side-pane-tree" "")
      (gtk_accel_path "<Actions>/ThunarWindow/toggle-side-pane" "")
      (gtk_accel_path "<Actions>/ThunarWindow/open-home" "<Shift>asciitilde")
      (gtk_accel_path "<Actions>/ThunarWindow/open-location-alt" "")
      (gtk_accel_path "<Actions>/ThunarWindow/search" "<Shift>exclam")
      (gtk_accel_path "<Actions>/ThunarStandardView/sort-by-type" "<Alt>3")
      (gtk_accel_path "<Actions>/ThunarWindow/switch-previous-tab" "")
      (gtk_accel_path "<Actions>/ThunarWindow/view-side-pane-shortcuts" "")
      (gtk_accel_path "<Actions>/ThunarWindow/close-window" "")
      (gtk_accel_path "<Actions>/ThunarStandardView/toggle-sort-order" "<Alt>grave")
      (gtk_accel_path "<Actions>/ThunarWindow/close-all-windows" "<Primary>q")
      (gtk_accel_path "<Actions>/ThunarWindow/view-menubar" "F1")
      (gtk_accel_path "<Actions>/ThunarWindow/new-tab" "")
      (gtk_accel_path "<Actions>/ThunarStandardView/sort-by-size" "<Alt>2")
      (gtk_accel_path "<Actions>/ThunarStandardView/sort-by-name" "<Alt>1")
    '';
  };

  cache.directories = [{
    method = "symlink";
    directory = "var/cache/thumbnails";
  }];

  xdg.mimeApps.defaultApplications = {
    "inode/directory" = "thunar.desktop";
    "inode/mount-point" = "thunar.desktop";
  };

  services.sxhkd.keybindings."super + o" = ''
    ${thunar}/bin/thunar ~
  '';
}

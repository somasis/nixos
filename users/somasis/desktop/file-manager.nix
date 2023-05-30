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

  thunar = pkgs.xfce.thunar-bare.overrideAttrs (prev: {
    configureFlags = prev.configureFlags ++ [
      # "--disable-gio-unix"
      # "--disable-gudev"
      "--disable-notifications"
      "--disable-wallpaper-plugin"
    ];
  });
in
{
  gtk.gtk3.bookmarks = map (x: "file://${x}") [
    "/home/somasis/mess/current"
    "/home/somasis/mess/current/incoming"
    "/home/somasis/mess/current/screenshots"
    "/home/somasis/mess/current/src"
    "/home/somasis/audio"
    "/home/somasis/audio/library/lossless"
    "/home/somasis/diary"
    "/home/somasis/ledger"
    "/home/somasis/list"
    "/home/somasis/mnt/gdrive"
    "/home/somasis/mnt/gphotos"
    "/home/somasis/mnt/sftp"
    "/home/somasis/pictures"
    "/home/somasis/shared"
    "/home/somasis/src"
    "/home/somasis/study/current"
    "/home/somasis/sync"
    "/home/somasis/tracks"
    "/home/somasis/video"
    "/home/somasis/video/film"
    "/home/somasis/video/tv"
    "/cache"
    "/log"
    "/persist"
  ];

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

      last-location-bar = "ThunarLocationEntry"; # View > Location selector > Buttons style
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

  xdg.configFile =
    let
      mkAccels = attrs: concatStringsSep "\n" (mapAttrsToList
        (action: key:
          let
            quote = escape [ "\"" ];
            key' =
              if key == null then
                quote ""
              else
                quote key
            ;
            action' = quote action;
          in
          ''(gtk_accel_path "<Actions>/${action'}" "${key'}")''
        )
        attrs
      );

      copy-file-contents = pkgs.writeShellScript "copy-file-contents" ''
        ${pkgs.xclip}/bin/xclip \
            -selection clipboard \
            -target "$(${pkgs.file}/bin/file -bL --mime-type "$1")" \
            -in "$1"
      '';

      ffmpeg = pkgs.writeShellScript "ffmpeg" ''
        export PATH=${lib.makeBinPath [ pkgs.coreutils pkgs.libnotify pkgs.nq pkgs.ffmpeg-full pkgs.xdg-utils ]}

        : "''${XDG_RUNTIME_DIR:=/run/user/$(id -u)}"
        export NQDIR="$XDG_RUNTIME_DIR/ffmpeg"
        mkdir -p "$NQDIR"
        jobs=$(fq -qn | wc -l)
        job_number=$(( jobs + 1 ))

        notification=$(
            notify-send -p \
                -a ffmpeg \
                -i "soundconverter" \
                "ffmpeg" \
                "Starting job #''${job_number}."
        )
        job=$(nq -c ffmpeg -y -hide_banner -nostdin "$@")

        {
            action=$(
                notify-send \
                    -r "$notification" \
                    -a "ffmpeg" \
                    -i "soundconverter" \
                    -A "View log" \
                    "ffmpeg" \
                    "Started job #''${job_number}."
            )

            case "$action" in
                'View log')
                    exec alacritty -T "ffmpeg" --hold fq "$job"
                    ;;
            esac
        } &


        nq -w "$job"

        if [ -e "$NQDIR/$job" ]; then
            notify-send \
                -r "$notification" \
                -a ffmpeg \
                -i "soundconverter" \
                "ffmpeg" \
                "Job #''${job_number} completed successfully."
        else
            action=$(
                notify-send \
                    -r "$notification" \
                    -a ffmpeg \
                    -i "soundconverter" \
                    -A "View log" \
                    "ffmpeg" \
                    "Job #''${job_number} failed to complete."
            )

            case "$action" in
                'View log')
                    xdg-open "$NQDIR/$job"
                    ;;
            esac
        fi
      '';
    in
    {
      "Thunar/uca.xml".text = config.lib.somasis.generators.toXML {
        actions = {
          action =
            let
              path = "%f";
              paths = "%F";
              parentDirectory = "%d";
              parentDirectories = "%D";
              file = "%n";
              files = "%N";
            in
            [
              {
                command = "${copy-file-contents} ${path}";
                description = "Copy the contents of the selected file to the clipboard.";
                icon = "edit-copy";
                name = "Copy file contents to clipboard";
                patterns = "*";
                audio-files = true;
                image-files = true;
                text-files = true;
                video-files = true;
                other-files = true;
                unique-id = "copy-file-contents";
              }
              {
                command = "${pkgs.execline}/bin/execline-cd ${path} alacritty";
                description = "Open a terminal in the selected or current directory";
                directories = false;
                icon = "terminal";
                name = "Open terminal here";
                patterns = "*";
                unique-id = "terminal";
              }
              {
                command = "wallpaperctl set -cover ${path}";
                description = "Set the selected image as the wallpaper";
                icon = "cs-backgrounds";
                image-files = true;
                name = "Set as wallpaper";
                patterns = "*";
                unique-id = "wallpaper";
              }
              {
                command = "${ffmpeg} -i ${path} -vn -b:a 320k ${path}.mp3";
                description = "Convert the selected audio file to a 320kbps MP3 file";
                audio-files = true;
                unique-id = "ffmpeg-mp3-320kbps";
                icon = "soundconverter";
                name = "Convert to MP3-320";
              }
              {
                command = "${ffmpeg} -i ${path} -vn -q:a 0 ${path}.mp3";
                description = "Convert the selected audio file to a VBR 0 MP3 file";
                audio-files = true;
                unique-id = "ffmpeg-mp3-V0";
                icon = "soundconverter";
                name = "Convert to MP3-V0";
              }
              {
                command = "${ffmpeg} -i ${path} -vn -q:a 2 ${path}.mp3";
                description = "Convert the selected audio file to a VBR 2 MP3 file";
                audio-files = true;
                unique-id = "ffmpeg-mp3-V2";
                icon = "soundconverter";
                name = "Convert to MP3-V2";
              }
              {
                command = "${ffmpeg} -i ${path} -vn -acodec libopus -ab 96k -ar 48000 ${path}.opus";
                description = "Convert the selected audio file to a 96k Opus file";
                audio-files = true;
                unique-id = "ffmpeg-opus-96k";
                icon = "soundconverter";
                name = "Convert to Opus (96k)";
              }
            ];
        };
      };

      "Thunar/accels.scm".text = mkAccels {
        "ThunarWindow/view-menubar" = "F1";
        "ThunarWindow/close-all-windows" = "<Primary>q";

        "ThunarStandardView/properties" = "grave";
        "ThunarStandardView/select-by-pattern" = "<Primary>f";

        "ThunarWindow/open-home" = "<Shift>asciitilde";
        "ThunarWindow/search" = "<Shift>exclam";

        "ThunarStandardView/toggle-sort-order" = "<Alt>grave";
        "ThunarStandardView/sort-by-name" = "<Alt>1";
        "ThunarStandardView/sort-by-size" = "<Alt>2";
        "ThunarStandardView/sort-by-type" = "<Alt>3";
        "ThunarStandardView/sort-by-mtime" = "<Alt>4";
        "ThunarStandardView/invert-selection" = "<Primary>i";

        "ThunarStandardView/back-alt" = null;
        "ThunarActionManager/open-in-new-tab" = null;
        "ThunarWindow/switch-next-tab" = null;
        "ThunarShortcutsPane/sendto-shortcuts" = null;
        "ThunarWindow/close-tab" = null;
        "ThunarWindow/view-side-pane-tree" = null;
        "ThunarWindow/toggle-side-pane" = null;
        "ThunarWindow/open-location-alt" = null;
        "ThunarWindow/switch-previous-tab" = null;
        "ThunarWindow/view-side-pane-shortcuts" = null;
        "ThunarWindow/close-window" = null;
        "ThunarWindow/new-tab" = null;
      };
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

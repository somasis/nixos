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
    "/home/somasis/video/anime"
    "/home/somasis/video/film"
    "/home/somasis/video/tv"
    "/cache"
    "/log"
    "/persist"
  ];

  dconf.settings = {
    "org/gtk/settings/file-chooser" = {
      clock-format = "12h";
      date-format = "with-time";
      show-hidden = true;
      show-size-column = true;
      show-type-column = true;
      sort-directories-first = true;
      startup-mode = "cwd";
      type-format = "mime";
    };

    "org/gtk/gtk4/settings/file-chooser" = {
      date-format = "with-time";
      show-hidden = true;
      sort-directories-first = true;
      type-format = "mime";
    };
  };

  home.packages = [
    thunar

    (pkgs.symlinkJoin {
      name = "tumbler-final";

      paths = [
        pkgs.xfce.tumbler
        pkgs.webp-pixbuf-loader # .webp
        pkgs.libgsf # .odf
        pkgs.nufraw-thumbnailer # .raw
        pkgs.gnome-epub-thumbnailer # .epub, .mobi
      ];
    })

    pkgs.xfce.xfconf

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

  xfconf.settings.thunar = let listToCommaStringList = l: commaList (map builtins.toString l); in {
    # Display > View settings
    misc-folders-first = true; # Sort folders before files
    misc-file-size-binary = true; # Show file size in binary format

    # Display > Thumbnails
    misc-thumbnail-mode = "THUNAR_THUMBNAIL_MODE_ONLY_LOCAL"; # Local files only
    misc-thumbnail-max-file-size = 1048576 * 100; # Only show thumbnails for files smaller than 100MiB
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
    misc-transfer-verify-file = "THUNAR_VERIFY_FILE_MODE_NEVER"; # Don't verify file checksums on copy

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
    misc-case-sensitive = true; # Use case sensitive sorting (and thus show hidden files first)

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
        export PATH=${lib.makeBinPath [ pkgs.file pkgs.xclip ]}

        xclip \
            -selection clipboard \
            -target "$(file -bL --mime-type "$1")" \
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
                    exec kitty -T "ffmpeg" --hold fq "$job"
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
      "Thunar/uca.xml".text = config.lib.somasis.generators.toXML { } {
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
                command = "kitty -d ${path}";
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
    directory = config.lib.somasis.xdgCacheDir "thumbnails";
  }];

  xdg.mimeApps.defaultApplications = {
    "inode/directory" = "thunar.desktop";
    "inode/mount-point" = "thunar.desktop";
  };

  services.sxhkd.keybindings."super + o" = ''
    ${thunar}/bin/thunar ~
  '';

  # programs.yazi = {
  #   enable = true;
  #   enableBashIntegration = true;

  #   settings = {
  #     manager = {
  #       layout = [ 1 5 6 ];
  #       show_hidden = true;
  #       show_symlink = false;

  #       sort_by = "natural";
  #       sort_dir_first = true;
  #       sort_reverse = false;
  #       sort_sensitive = true;
  #     };

  #     open = {
  #       rules = [
  #         { name = "*/"; use = "folder"; }
  #         { mime = "text/*"; use = "text"; }
  #         { mime = "image/*"; use = "image"; }
  #         { mime = "video/*"; use = "video"; }
  #         { mime = "audio/*"; use = "audio"; }
  #         { mime = "inode/x-empty"; use = "text"; }
  #         { mime = "application/json"; use = "text"; }
  #         { mime = "*/javascript"; use = "text"; }
  #         { mime = "application/zip"; use = "archive"; }
  #         { mime = "application/gzip"; use = "archive"; }
  #         { mime = "application/x-tar"; use = "archive"; }
  #         { mime = "application/x-bzip"; use = "archive"; }
  #         { mime = "application/x-bzip2"; use = "archive"; }
  #         { mime = "application/x-7z-compressed"; use = "archive"; }
  #         { mime = "application/x-rar"; use = "archive"; }
  #         { mime = "*"; use = "fallback"; }
  #       ];
  #     };

  #     opener = {
  #       archive = [{ block = true; display_name = "Extract here"; exec = "tar -xvf \"$1\""; }];

  #       audio = [{ exec = "mpv \"$@\""; }];

  #       image = [
  #         { display_name = "Open"; exec = "open \"$@\""; }
  #         { block = true; display_name = "Show EXIF"; exec = "exiftool \"$1\"; echo \"Press enter to exit\"; read"; }
  #       ];

  #       text = [{ block = true; exec = "$EDITOR \"$@\""; }];

  #       video = [{ exec = "mpv \"$@\""; }];

  #       folder = [{ exec = "$EDITOR \"$@\""; }];
  #       fallback = [{ display_name = "Open"; exec = "xdg-open \"$1\""; }];
  #     };

  #     preview = {
  #       max_height = 900;
  #       max_width = 600;
  #       tab_size = 4;
  #     };

  #     tasks = {
  #       bizarre_retry = 5;
  #       macro_workers = 10;
  #       micro_workers = 5;
  #     };
  #   };

  #   keymap = {
  #     manager = {
  #       keymap = [
  #         { desc = "Run a shell command"; exec = "shell"; on = [ "!" ]; }
  #         {
  #           desc = "Run a shell command (blocking until it finishes)";
  #           exec = "shell --block";
  #           on = [
  #             "$"
  #           ];
  #         }
  #         { desc = "Exit visual mode, clear selected, or cancel search"; exec = "escape"; on = [ "<Esc>" ]; }
  #         { desc = "Exit the process"; exec = "quit"; on = [ "q" ]; }
  #         { desc = "Close the current tab, or quit if it is last tab"; exec = "close"; on = [ "<C-q>" ]; }
  #         { desc = "Suspend the process"; exec = "suspend"; on = [ "<C-z>" ]; }
  #         { desc = "Move cursor up"; exec = "arrow -1"; on = [ "k" ]; }
  #         { desc = "Move cursor down"; exec = "arrow 1"; on = [ "j" ]; }
  #         { desc = "Move cursor up 5 lines"; exec = "arrow -5"; on = [ "K" ]; }
  #         { desc = "Move cursor down 5 lines"; exec = "arrow 5"; on = [ "J" ]; }
  #         { desc = "Move cursor up half page"; exec = "arrow -50%"; on = [ "<C-u>" ]; }
  #         { desc = "Move cursor down half page"; exec = "arrow 50%"; on = [ "<C-d>" ]; }
  #         { desc = "Move cursor up half page"; exec = "arrow -50%"; on = [ "<PageUp>" ]; }
  #         { desc = "Move cursor down half page"; exec = "arrow 50%"; on = [ "<PageDown>" ]; }
  #         { desc = "Move cursor up one page"; exec = "arrow -100%"; on = [ "<C-b>" ]; }
  #         { desc = "Move cursor down one page"; exec = "arrow 100%"; on = [ "<C-f>" ]; }
  #         { desc = "Go back to the parent directory"; exec = "leave"; on = [ "h" ]; }
  #         { desc = "Enter the child directory"; exec = "enter"; on = [ "l" ]; }
  #         { desc = "Go back to the previous directory"; exec = "back"; on = [ "H" ]; }
  #         { desc = "Go forward to the next directory"; exec = "forward"; on = [ "L" ]; }
  #         { desc = "Peek up 5 units in the preview"; exec = "peek -5"; on = [ "<C-k>" ]; }
  #         { desc = "Peek down 5 units in the preview"; exec = "peek 5"; on = [ "<C-j>" ]; }
  #         { desc = "Move cursor up"; exec = "arrow -1"; on = [ "<Up>" ]; }
  #         { desc = "Move cursor down"; exec = "arrow 1"; on = [ "<Down>" ]; }
  #         { desc = "Go back to the parent directory"; exec = "leave"; on = [ "<Left>" ]; }
  #         { desc = "Enter the child directory"; exec = "enter"; on = [ "<Right>" ]; }
  #         { desc = "Move cursor to the top"; exec = "arrow -99999999"; on = [ "g" "g" ]; }
  #         { desc = "Move cursor to the bottom"; exec = "arrow 99999999"; on = [ "g" "G" ]; }
  #         { desc = "Move cursor to the top"; exec = "arrow -99999999"; on = [ "<Home>" ]; }
  #         { desc = "Move cursor to the bottom"; exec = "arrow 99999999"; on = [ "<End>" ]; }
  #         {
  #           desc = "Toggle the current selection state";
  #           exec = [ "select --state=none" "arrow 1" ];
  #           on = [
  #             "<Space>"
  #           ];
  #         }
  #         {
  #           desc = "Enter visual mode (selection mode)";
  #           exec = "visual_mode";
  #           on = [
  #             "v"
  #           ];
  #         }
  #         {
  #           desc = "Enter visual mode (unset mode)";
  #           exec = "visual_mode --unset";
  #           on = [
  #             "V"
  #           ];
  #         }
  #         { desc = "Select all files"; exec = "select_all --state=true"; on = [ "<C-a>" ]; }
  #         { desc = "Inverse selection of all files"; exec = "select_all --state=none"; on = [ "<C-r>" ]; }
  #         { desc = "Open the selected files"; exec = "open"; on = [ "o" ]; }
  #         { desc = "Open the selected files interactively"; exec = "open --interactive"; on = [ "O" ]; }
  #         { desc = "Open the selected files"; exec = "open"; on = [ "<Enter>" ]; }
  #         { desc = "Open the selected files interactively"; exec = "open --interactive"; on = [ "<C-Enter>" ]; }
  #         { desc = "Copy the selected files"; exec = "yank"; on = [ "y" ]; }
  #         { desc = "Cut the selected files"; exec = "yank --cut"; on = [ "x" ]; }
  #         { desc = "Paste the files"; exec = "paste"; on = [ "p" ]; }
  #         {
  #           desc = "Paste the files (overwrite if the destination exists)";
  #           exec = "paste --force";
  #           on = [
  #             "P"
  #           ];
  #         }
  #         { desc = "Symlink the absolute path of files"; exec = "link"; on = [ "n" ]; }
  #         { desc = "Symlink the relative path of files"; exec = "link --relative"; on = [ "N" ]; }
  #         { desc = "Move the files to the trash"; exec = "remove"; on = [ "d" ]; }
  #         { desc = "Permanently delete the files"; exec = "remove --permanently"; on = [ "D" ]; }
  #         {
  #           desc = "Create a file or directory (ends with / for directories)";
  #           exec = "create";
  #           on = [
  #             "a"
  #           ];
  #         }
  #         { desc = "Rename a file or directory"; exec = "rename"; on = [ "r" ]; }
  #         { desc = "Toggle the visibility of hidden files"; exec = "hidden toggle"; on = [ "." ]; }
  #         { desc = "Search files by name using sk"; exec = "search sk"; on = [ "s" ]; }
  #         { desc = "Cancel the ongoing search"; exec = "search none"; on = [ "<C-s>" ]; }
  #         { desc = "Jump to a directory using skim"; exec = "jump sk"; on = [ "z" ]; }
  #         { desc = "Copy the absolute path"; exec = "copy path"; on = [ "c" "c" ]; }
  #         { desc = "Copy the path of the parent directory"; exec = "copy dirname"; on = [ "c" "d" ]; }
  #         { desc = "Copy the name of the file"; exec = "copy filename"; on = [ "c" "f" ]; }
  #         { desc = "Copy the name of the file without the extension"; exec = "copy name_without_ext"; on = [ "c" "n" ]; }
  #         { exec = "find"; on = [ "/" ]; }
  #         { exec = "find --previous"; on = [ "?" ]; }
  #         { exec = "find_arrow"; on = [ "-" ]; }
  #         { exec = "find_arrow --previous"; on = [ "=" ]; }
  #         { desc = "Sort alphabetically"; exec = "sort alphabetical --dir_first"; on = [ "," "a" ]; }
  #         {
  #           desc = "Sort alphabetically (reverse)";
  #           exec = "sort alphabetical --reverse --dir_first";
  #           on = [
  #             ","
  #             "A"
  #           ];
  #         }
  #         { desc = "Sort by creation time"; exec = "sort created --dir_first"; on = [ "," "c" ]; }
  #         {
  #           desc = "Sort by creation time (reverse)";
  #           exec = "sort created --reverse --dir_first";
  #           on = [
  #             ","
  #             "C"
  #           ];
  #         }
  #         { desc = "Sort by modified time"; exec = "sort modified --dir_first"; on = [ "," "m" ]; }
  #         {
  #           desc = "Sort by modified time (reverse)";
  #           exec = "sort modified --reverse --dir_first";
  #           on = [
  #             ","
  #             "M"
  #           ];
  #         }
  #         { desc = "Sort naturally"; exec = "sort natural --dir_first"; on = [ "," "n" ]; }
  #         {
  #           desc = "Sort naturally (reverse)";
  #           exec = "sort natural --reverse --dir_first";
  #           on = [
  #             ","
  #             "N"
  #           ];
  #         }
  #         { desc = "Sort by size"; exec = "sort size --dir_first"; on = [ "," "s" ]; }
  #         {
  #           desc = "Sort by size (reverse)";
  #           exec = "sort size --reverse --dir_first";
  #           on = [
  #             ","
  #             "S"
  #           ];
  #         }
  #         { desc = "Create a new tab using the current path"; exec = "tab_create --current"; on = [ "t" ]; }
  #         { desc = "Switch to the first tab"; exec = "tab_switch 0"; on = [ "1" ]; }
  #         { desc = "Switch to the second tab"; exec = "tab_switch 1"; on = [ "2" ]; }
  #         { desc = "Switch to the third tab"; exec = "tab_switch 2"; on = [ "3" ]; }
  #         { desc = "Switch to the fourth tab"; exec = "tab_switch 3"; on = [ "4" ]; }
  #         { desc = "Switch to the fifth tab"; exec = "tab_switch 4"; on = [ "5" ]; }
  #         { desc = "Switch to the sixth tab"; exec = "tab_switch 5"; on = [ "6" ]; }
  #         { desc = "Switch to the seventh tab"; exec = "tab_switch 6"; on = [ "7" ]; }
  #         { desc = "Switch to the eighth tab"; exec = "tab_switch 7"; on = [ "8" ]; }
  #         { desc = "Switch to the ninth tab"; exec = "tab_switch 8"; on = [ "9" ]; }
  #         { desc = "Switch to the previous tab"; exec = "tab_switch -1 --relative"; on = [ "[" ]; }
  #         { desc = "Switch to the next tab"; exec = "tab_switch 1 --relative"; on = [ "]" ]; }
  #         { desc = "Swap the current tab with the previous tab"; exec = "tab_swap -1"; on = [ "{" ]; }
  #         {
  #           desc = "Swap the current tab with the next tab";
  #           exec = "tab_swap 1";
  #           on = [
  #             "}"
  #           ];
  #         }
  #         { desc = "Show the tasks manager"; exec = "tasks_show"; on = [ "w" ]; }
  #         { desc = "Go to the home directory"; exec = "cd ~"; on = [ "g" "h" ]; }
  #         { desc = "Go to the config directory"; exec = "cd ~/.config"; on = [ "g" "c" ]; }
  #         { desc = "Go to the downloads directory"; exec = "cd ~/Downloads"; on = [ "g" "d" ]; }
  #         { desc = "Go to the temporary directory"; exec = "cd /tmp"; on = [ "g" "t" ]; }
  #         { desc = "Go to a directory interactively"; exec = "cd --interactive"; on = [ "g" "<Space>" ]; }
  #         { desc = "Open help"; exec = "help"; on = [ "~" ]; }
  #       ];
  #     };

  #     select = {
  #       keymap = [
  #         { desc = "Cancel selection"; exec = "close"; on = [ "<C-q>" ]; }
  #         { desc = "Cancel selection"; exec = "close"; on = [ "<Esc>" ]; }
  #         { desc = "Submit the selection"; exec = "close --submit"; on = [ "<Enter>" ]; }
  #         { desc = "Move cursor up"; exec = "arrow -1"; on = [ "k" ]; }
  #         { desc = "Move cursor down"; exec = "arrow 1"; on = [ "j" ]; }
  #         { desc = "Move cursor up 5 lines"; exec = "arrow -5"; on = [ "K" ]; }
  #         { desc = "Move cursor down 5 lines"; exec = "arrow 5"; on = [ "J" ]; }
  #         { desc = "Move cursor up"; exec = "arrow -1"; on = [ "<Up>" ]; }
  #         { desc = "Move cursor down"; exec = "arrow 1"; on = [ "<Down>" ]; }
  #         { desc = "Open help"; exec = "help"; on = [ "~" ]; }
  #       ];
  #     };

  #     input = {
  #       keymap = [
  #         { desc = "Cancel input"; exec = "close"; on = [ "<C-q>" ]; }
  #         { desc = "Submit the input"; exec = "close --submit"; on = [ "<Enter>" ]; }
  #         { desc = "Go back the normal mode, or cancel input"; exec = "escape"; on = [ "<Esc>" ]; }
  #         { desc = "Enter insert mode"; exec = "insert"; on = [ "i" ]; }
  #         { desc = "Enter append mode"; exec = "insert --append"; on = [ "a" ]; }
  #         { desc = "Enter visual mode"; exec = "visual"; on = [ "v" ]; }
  #         {
  #           desc = "Enter visual mode and select all";
  #           exec = [ "move -999" "visual" "move 999" ];
  #           on = [
  #             "V"
  #           ];
  #         }
  #         { desc = "Move cursor left"; exec = "move -1"; on = [ "h" ]; }
  #         { desc = "Move cursor right"; exec = "move 1"; on = [ "l" ]; }
  #         { desc = "Move to the BOL"; exec = "move -999"; on = [ "<Home>" ]; }
  #         { desc = "Move to the EOL"; exec = "move 999"; on = [ "<End>" ]; }
  #         {
  #           desc = "Move to the BOL, and enter insert mode";
  #           exec = [ "move -999" "insert" ];
  #           on = [
  #             "I"
  #           ];
  #         }
  #         {
  #           desc = "Move to the EOL, and enter append mode";
  #           exec = [ "move 999" "insert --append" ];
  #           on = [
  #             "A"
  #           ];
  #         }
  #         { desc = "Move cursor left"; exec = "move -1"; on = [ "<Left>" ]; }
  #         { desc = "Move cursor right"; exec = "move 1"; on = [ "<Right>" ]; }
  #         { desc = "Move to the beginning of the previous word"; exec = "backward"; on = [ "b" ]; }
  #         { desc = "Move to the beginning of the next word"; exec = "forward"; on = [ "w" ]; }
  #         { desc = "Move to the end of the next word"; exec = "forward --end-of-word"; on = [ "e" ]; }
  #         { desc = "Cut the selected characters"; exec = "delete --cut"; on = [ "d" ]; }
  #         {
  #           desc = "Cut until the EOL";
  #           exec = [ "delete --cut" "move 999" ];
  #           on = [
  #             "D"
  #           ];
  #         }
  #         { desc = "Cut the selected characters, and enter insert mode"; exec = "delete --cut --insert"; on = [ "c" ]; }
  #         {
  #           desc = "Cut until the EOL, and enter insert mode";
  #           exec = [ "delete --cut --insert" "move 999" ];
  #           on = [
  #             "C"
  #           ];
  #         }
  #         {
  #           desc = "Cut the current character";
  #           exec = [ "delete --cut" "move 1 --in-operating" ];
  #           on = [
  #             "x"
  #           ];
  #         }
  #         { desc = "Copy the selected characters"; exec = "yank"; on = [ "y" ]; }
  #         { desc = "Paste the copied characters after the cursor"; exec = "paste"; on = [ "p" ]; }
  #         { desc = "Paste the copied characters before the cursor"; exec = "paste --before"; on = [ "P" ]; }
  #         { desc = "Undo the last operation"; exec = "undo"; on = [ "u" ]; }
  #         { desc = "Redo the last operation"; exec = "redo"; on = [ "<C-r>" ]; }
  #         { desc = "Open help"; exec = "help"; on = [ "~" ]; }
  #       ];
  #     };

  #     tasks = {
  #       keymap = [
  #         { desc = "Hide the task manager"; exec = "close"; on = [ "<Esc>" ]; }
  #         { desc = "Hide the task manager"; exec = "close"; on = [ "<C-q>" ]; }
  #         { desc = "Hide the task manager"; exec = "close"; on = [ "w" ]; }
  #         { desc = "Move cursor up"; exec = "arrow -1"; on = [ "k" ]; }
  #         { desc = "Move cursor down"; exec = "arrow 1"; on = [ "j" ]; }
  #         { desc = "Move cursor up"; exec = "arrow -1"; on = [ "<Up>" ]; }
  #         { desc = "Move cursor down"; exec = "arrow 1"; on = [ "<Down>" ]; }
  #         { desc = "Inspect the task"; exec = "inspect"; on = [ "<Enter>" ]; }
  #         { desc = "Cancel the task"; exec = "cancel"; on = [ "x" ]; }
  #         { desc = "Open help"; exec = "help"; on = [ "~" ]; }
  #       ];
  #     };

  #     help = {
  #       keymap = [
  #         { desc = "Clear the filter, or hide the help"; exec = "escape"; on = [ "<Esc>" ]; }
  #         { desc = "Exit the process"; exec = "close"; on = [ "q" ]; }
  #         { desc = "Hide the help"; exec = "close"; on = [ "<C-q>" ]; }
  #         { desc = "Move cursor up"; exec = "arrow -1"; on = [ "k" ]; }
  #         { desc = "Move cursor down"; exec = "arrow 1"; on = [ "j" ]; }
  #         { desc = "Move cursor up 5 lines"; exec = "arrow -5"; on = [ "K" ]; }
  #         { desc = "Move cursor down 5 lines"; exec = "arrow 5"; on = [ "J" ]; }
  #         { desc = "Move cursor up"; exec = "arrow -1"; on = [ "<Up>" ]; }
  #         { desc = "Move cursor down"; exec = "arrow 1"; on = [ "<Down>" ]; }
  #         { desc = "Apply a filter for the help items"; exec = "filter"; on = [ "/" ]; }
  #       ];
  #     };
  #   };
  # };

  programs.lf = {
    enable = true;

    settings = {
      promptfmt = ''\033[34m%u\033[0m \033[1;39m%d\033[0m'';

      statfmt = "";

      # Dim selection cursor in other columns.
      cursorpreviewfmt = ''\033[7;90m'';

      icons = true;

      hidden = true;

      # Search for each keystroke.
      incsearch = true;

      mouse = true;

      # Always keep selection in middle of screen.
      scrolloff = 999999999;

      cleaner = builtins.toString (pkgs.writeShellScript "lf-cleaner" ''
        kitty +kitten icat \
            --clear \
            --stdin=no \
            --silent \
            --transfer-mode=file \
            </dev/null \
            >/dev/tty
      '');
    };

    commands = {
      on-select = ''
        %{{
          PATH=${lib.makeBinPath [ pkgs.file pkgs.s6-portable-utils pkgs.coreutils ]}:"$PATH"

          set -f

          path="$f"
          file=$(basename "$path" 2>/dev/null)
          dir=$(dirname "$path" 2>/dev/null)
          [ -d "$path" ] || cd "$dir" >/dev/null 2>&1

          ls=
          mime=
          ls=$(${config.home.shellAliases.ls} --color=always -d "$file" || :)
          mime=$(file -Lb --mime-type "$file" || :)

          stat="$ls $mime"
          stat=$(s6-quote-filter -d "'" <<<"$stat")

          lf -remote "send $id set statfmt $stat"
        }}
      '';

      on-cd = ''
        &{{
            # '&' commands run silently in background (which is what we want here),
            # but are not connected to stdout.
            # To make sure our escape sequence still reaches stdout we pipe it to /dev/tty
            printf '\033]0; lf: %s\007' "$PWD" > /dev/tty
        }}
      '';
    };

    extraConfig = ''
      on-cd

      cmd reload-config $lf -remote "send $id source "''${XDG_CONFIG_HOME:-$HOME/.config}/lf/lfrc"
      map r reload-config
    '';

    keybindings = {
      "<c-z>" = "bg";
    };

    cmdKeybindings = {
      "<enter>" = "open";
    };

    previewer = {
      keybinding = "i";
      source = pkgs.writeShellScript "lf-preview" ''
        PATH=${lib.makeBinPath [ pkgs.coreutils pkgs.file pkgs.bubblewrap config.programs.kitty.package ]}:"$PATH"

        set -euo pipefail
        set -f

        sandbox() (
            : "''${TMPDIR:=/tmp}"
            : "''${XDG_RUNTIME_DIR:=/run/user/$(id -u)}"
            : "''${XDG_CACHE_HOME:=$HOME/.cache}"
            : "''${XDG_CONFIG_HOME:=$HOME/.config}"

            exec bwrap \
                 --proc /proc \
                 --dev /dev  \
                 --ro-bind  /nix                /nix \
                 --bind     "$XDG_RUNTIME_DIR"  "$XDG_RUNTIME_DIR" \
                 --bind     "$TMPDIR"           "$TMPDIR" \
                 --ro-bind  "$XDG_CONFIG_HOME"  "$XDG_CONFIG_HOME" \
                 --ro-bind  "$XDG_CACHE_HOME"   "$XDG_CACHE_HOME" \
                 --ro-bind  "$PWD"              "$PWD" \
                 --unshare-all \
                 --new-session \
                 "$@"
        )

        file="$1"
        preview_width="$2"
        preview_height="$3"
        preview_x="$4"
        preview_y="$5"

        file_mime=
        file_encoding=
        file_mime=$(file -Lb --mime "$file")
        IFS='; =' read -r file_mime _ file_encoding _ <<<"$file_mime" || :

        case "$file_mime" in
            'image/'*)
                kitty +kitten icat \
                    --silent \
                    --stdin=no \
                    --place="''${preview_w}x''${preview_h}@''${preview_x}x''${preview_y}" \
                    "$file" \
                    < /dev/null \
                    > /dev/tty

                # Always exit unsuccessfully, so as to trigger the cleaner command.
                exit 1
                ;;
            *)
                # case "$file_encoding" in
                #     binary) : ;;

                #     *)
                #         fold -w "$w" "$file" || :
                #         ;;
                # esac
                lesspipe.sh "$file"
                ;;
        esac
      '';
    };
  };
}

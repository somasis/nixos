# Convert to Opus for other devices
{ lib
, config
, pkgs
, music
, ...
}: {
  programs.beets.settings = rec {
    plugins = [ "convert" ];
    convert = {
      # auto = true;

      copy_album_art = true;
      embed = false;
      album_art_maxwidth = 2048;

      dest = "${config.xdg.userDirs.music}/lossy";

      format = "opus";
      formats.opus = {
        command = "${pkgs.ffmpeg-full}/bin/ffmpeg -i $source -y -vn -acodec libopus -ab 96k -ar 48000 $dest";
        extension = "opus";
      };

      paths.default = "%if{$mb_albumartistid,$mb_albumartistid/}%if{$mb_albumid,$mb_albumid/}%ifdef{mb_releasetrackid,%ifdef{mb_trackid}}";
    };

    hook.hooks =
      let
        # Propagate item changes in the main library to the converted library
        hookPushItemToConverted = (pkgs.writeShellScript "beet-hook-push-item-to-converted" ''
          ${lib.toShellVar "path_converted" convert.dest}
          ${lib.toShellVar "extension_converted" convert.formats."${convert.format}".extension}
          ${lib.toShellVar "format_converted" convert.paths.default}

          converted_path=$(beet list -f "$path_converted/$format_converted.$extension_converted" "path:$1")
          converted_album_path=$(dirname "$converted_path")

          rm -f "$converted_path"
          find "$converted_album_path" -name 'cover.*' -delete
          beet convert -ay "path:$1"
        '');

        # Remove items from the converted library when they're removed from the main library
        hookRemoveItemFromConverted = (pkgs.writeShellScript "beet-hook-remove-item-from-converted" ''
          ${lib.toShellVar "path_converted" convert.dest}
          ${lib.toShellVar "extension_converted" convert.formats."${convert.format}".extension}
          ${lib.toShellVar "format_converted" convert.paths.default}

          converted_path=$(beet list -f "$path_converted/$format_converted.$extension_converted" "path:$1")
          rm -f "$converted_path"
        '');

        # Remove albums from the converted library when they're removed from the main library
        hookRemoveAlbumFromConverted = (pkgs.writeShellScript "beet-hook-remove-album-from-converted" ''
          ${lib.toShellVar "path_converted" convert.dest}
          ${lib.toShellVar "extension_converted" convert.formats."${convert.format}".extension}
          ${lib.toShellVar "format_converted" convert.paths.default}

          converted_path=$(beet list -f "$path_converted/$format_converted.$extension_converted" "path:$1")
          converted_album_path=$(dirname "$converted_path")
          rm -r "$converted_album_path"
        '');
      in
      [
        { event = "after_write"; command = "${hookPushItemToConverted} {item.path}"; }
        { event = "item_removed"; command = "${hookRemoveItemFromConverted} {item.path}"; }
        { event = "album_removed"; command = "${hookRemoveAlbumFromConverted} {album.path}"; }
      ];
  };
}

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
        # Remove files from the converted library when they're removed from the library
        hookConvertItemRemoved = (pkgs.writeShellScript "beet-hook-convert-item-removed" ''
          ${lib.toShellVar "path_converted" convert.dest}
          ${lib.toShellVar "extension_converted" convert.formats."${convert.format}".extension}
          ${lib.toShellVar "format_converted" convert.paths.default}

          converted_path=$(beet list -f "$path_converted/$format_converted.$extension_converted" "path:$1")
          [[ -e "$converted_path" ]] && echo rm -f "$converted_path"
          echo find "$converted_path" -type d -empty
        '');
      in
      [
        { event = "item_removed"; command = "${hookConvertItemRemoved} {item.path}"; }
      ];
  };
}

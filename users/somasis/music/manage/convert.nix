# Convert to Opus for other devices
{ lib
, config
, pkgs
, music
, ...
}: {
  programs.beets.settings = rec {
    plugins = [ "convert" "alternatives" ];

    alternatives.lossy = {
      directory = "${config.xdg.userDirs.music}/lossy";
      formats = [ "opus" ];

      query = "";

      paths.default = "%if{$mb_albumartistid,$mb_albumartistid/}%if{$mb_albumid,$mb_albumid/}%ifdef{mb_releasetrackid,%ifdef{mb_trackid}}";

      removable = false;
    };

    convert = {
      # auto = true;

      copy_album_art = true;
      embed = false;
      album_art_maxwidth = 2048;

      dest = "${config.xdg.userDirs.music}/lossy";

      format = "opus";
      formats.opus = {
        # Set the sample rate to 48kHz so that anything above that isn't converted
        # with its original sample rate, which wastes space for lossy audio
        command = "${pkgs.ffmpeg-full}/bin/ffmpeg -i $source -y -vn -acodec libopus -ab 96k -ar 48000 $dest";
        extension = "opus";
      };

      paths.default = "%if{$mb_albumartistid,$mb_albumartistid/}%if{$mb_albumid,$mb_albumid/}%ifdef{mb_releasetrackid,%ifdef{mb_trackid}}";
    };
  };
}

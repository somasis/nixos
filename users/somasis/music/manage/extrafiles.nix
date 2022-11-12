# Copy over and organize extra files of all sorts
{ config, ... }: {
  programs.beets.settings = {
    plugins = [ "extrafiles" ];

    extrafiles = {
      patterns = {
        origin = [ config.programs.beets.settings.originquery.origin_file ];

        art = [
          "*[Aa]rt*/"
          "*[Ss]can*/"
        ];

        meta = [
          "*.[Ff][Ff][Pp]"
          "*.[Hh][Tt][Mm][Ll]"
          "*.[Mm][Dd]5"
          "*.[Mm][Ii][Dd]"
          "*.[Pp][Dd][Ff]"
          "*.[Rr][Tt][Ff]"
          "*.[Ss][Ff][Vv]"
          "*.[Tt][Oo][Cc]"
          "*.[Tt][Xx][Tt]"
          "*.[Yy][Aa][Mm][Ll]"
        ];
      };

      paths = {
        origin = "$albumpath/origin/";
        art = "$albumpath/art/";
        meta = "$albumpath/meta/";
      };
    };
  };
}

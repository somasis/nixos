# Copy over and organize extra files of all sorts
{ config, ... }: {
  programs.beets.settings = {
    plugins = [ "extrafiles" ];

    extrafiles = {
      patterns = {
        origin = [
          config.programs.beets.settings.originquery.origin_file
          "*.[Aa][Cc][Cc][Uu][Rr][Ii][Pp]"
          "*.[Cc][Uu][Ee]"
          "*.[Ll][Oo][Gg]"
          "*.[Nn][Ff][Oo]"
        ];

        art = [
          "*.[Gg][Ii][Ff]"
          "*.[Jj][Pp][Ee][Gg]"
          "*.[Jj][Pp][Gg]"
          "*.[Pp][Nn][Gg]"
          "*[Aa]rt*/*"
          "*[Ss]can*/*"
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

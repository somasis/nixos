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
          "*.[Ff][Ff][Pp]"
          "*.[Ll][Oo][Gg]"
          "*.[Mm][Dd]5"
          "*.[Ss][Ff][Vv]"
        ];

        art = [
          "[Aa]rt*/*"
          "[Ss]can*/*"
        ];

        misc = [
          "*.[Hh][Tt][Mm][Ll]"
          "*.[Pp][Dd][Ff]"
          "*.[Rr][Tt][Ff]"
          "*.[Tt][Oo][Cc]"
          "*.[Tt][Xx][Tt]"
        ];
      };

      paths = {
        origin = "$albumpath/$filename";
        art = "$albumpath/art/$filename";
        misc = "$albumpath/misc/$filename";
      };
    };
  };
}

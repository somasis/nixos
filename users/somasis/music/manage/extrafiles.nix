# Copy over and organize extra files of all sorts
{ config, ... }: {
  programs.beets.settings = {
    plugins = [ "extrafiles" ];

    extrafiles = {
      patterns = {
        art = [
          "*.[Gg][Ii][Ff]"
          "*.[Jj][Pp][Ee][Gg]"
          "*.[Jj][Pp][Gg]"
          "*.[Pp][Nn][Gg]"
          "*[Aa]rt/"
          "*[Aa]rtwork/"
          "*[Ss]can/"
          "*[Ss]cans/"
        ];

        meta = [
          config.programs.beets.settings.originquery.origin_file
          "*.[Aa][Cc][Cc][Uu][Rr][Ii][Pp]"
          "*.[Cc][Uu][Ee]"
          "*.[Ff][Ff][Pp]"
          "*.[Hh][Tt][Mm][Ll]"
          "*.[Ll][Oo][Gg]"
          "*.[Mm][Dd]5"
          "*.[Mm][Ii][Dd]"
          "*.[Nn][Ff][Oo]"
          "*.[Pp][Dd][Ff]"
          "*.[Rr][Tt][Ff]"
          "*.[Ss][Ff][Vv]"
          "*.[Tt][Oo][Cc]"
          "*.[Tt][Xx][Tt]"
          "*.[Yy][Aa][Mm][Ll]"
        ];
      };

      paths = {
        art = "$albumpath/art";
        meta = "$albumpath/meta";
      };
    };
  };
}

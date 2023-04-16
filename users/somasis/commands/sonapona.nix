{ config, pkgs, ... }:
let
  directory = "share/sonapona";
in
{
  home.packages = [
    (pkgs.writeShellApplication {
      name = "sonapona";

      runtimeInputs = [
        pkgs.bfs
        pkgs.coreutils
        pkgs.xe
        pkgs.gnused
      ];

      text = ''
        bfs "$HOME/${directory}" \
            -mindepth 2 -type f ! -executable \
            "$@" -exec shuf -n 1 -e {} + \
            | xe fold -w 80 -s \
            | sed 's/ *$//'
      '';
    })
  ];

  home.persistence."/persist${config.home.homeDirectory}".directories = [{
    method = "symlink";
    inherit directory;
  }];

  somasis.chrome.stw.widgets = [
    {
      name = "sonapona";

      text = {
        font = "monospace:style=heavy:size=10";
        color = config.xresources.properties."*darkForeground";
      };

      window = {
        color = config.xresources.properties."*color4";
        opacity = 0.15;
        position = {
          x = -24;
          y = -24;
        };

        padding = 12;
      };

      update = 60;

      command = "sonapona ! -name '*.long'";
    }
  ];
}

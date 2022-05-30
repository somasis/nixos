{ config, pkgs, ... }:
let
  dir = "share/sonapona";
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
        bfs "$HOME/${dir}" \
            -mindepth 2 -type f ! -executable \
            "$@" -exec shuf -n 1 -e {} + \
            | xe fold -w 80 -s \
            | sed 's/ *$//'
      '';
    })
  ];

  home.persistence."/persist${config.home.homeDirectory}".directories = [ "${dir}" ];
}

{ pkgs, config, ... }: {
  home.packages = [
    pkgs.prismlauncher
    pkgs.jdk
  ];

  home.persistence."/persist${config.home.homeDirectory}".directories = [ "share/PolyMC" ];

  # TODO use NixMinecraft?
  # programs.minecraft = {
  #   shared = {
  #     username = "somasis";
  #   };
  # };
}

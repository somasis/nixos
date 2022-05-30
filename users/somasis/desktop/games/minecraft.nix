{ pkgs, config, ... }: {
  home.packages = [
    pkgs.polymc
    pkgs.jdk
  ];

  home.persistence."/persist${config.home.homeDirectory}".directories = [
    "share/PolyMC"
  ];

  # programs.minecraft = {
  #   shared = {
  #     username = "somasis";
  #   };
  # };
}

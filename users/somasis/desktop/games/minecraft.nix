{ pkgs, config, ... }: {
  home.packages = [
    pkgs.prismlauncher
    pkgs.jdk
  ];

  home.persistence."/persist${config.home.homeDirectory}".directories = [{
    method = "symlink";
    directory = "share/PrismLauncher";
  }];

  # TODO use NixMinecraft?
  # programs.minecraft = {
  #   shared = {
  #     username = "somasis";
  #   };
  # };
}

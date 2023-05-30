{ pkgs, config, ... }: {
  home.packages = [
    pkgs.prismlauncher
    pkgs.jdk
  ];

  persist.directories = [{
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

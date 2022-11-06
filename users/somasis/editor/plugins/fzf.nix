{ pkgs, ... }: {
  programs.kakoune = {
    plugins = [
      pkgs.kakounePlugins.fzf-kak
    ];

    extraConfig = ''
      hook -once global ModuleLoaded fzf %{
          map global normal <c-o> ': fzf-mode<ret>f'
      }
    '';
  };
}

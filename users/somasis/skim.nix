{
  programs.skim = {
    enable = true;
    defaultOptions = [ "--exact" "--layout reverse" "--prompt '/ '" "--cmd-prompt '∴ '" ];
  };

  programs.kakoune.extraConfig = ''
    hook -once global ModuleLoaded fzf %{
        set-option global fzf_implementation "sk"
    }
  '';
}

{ pkgs, ... }: {
  programs.kakoune = {
    extraConfig = ''
      eval %sh{ kak-lsp --kakoune -s $kak_session }
      lsp-enable
    '';

    plugins = [ pkgs.kak-lsp ];
  };

  xdg.configFile."kak-lsp/kak-lsp.toml".source = (pkgs.formats.toml { }).generate "kak-lsp.toml" {
    language = {
      bash = {
        filetypes = [ "sh" ];
        roots = [ ".git" ".hg" ];
        command = "${pkgs.nodePackages.bash-language-server}/bin/bash-language-server";
        args = [ "start" ];
      };

      c_cpp = {
        filetypes = [ "c" "cpp" ];
        roots = [ "compile_commands.json" ".clangd" ".git" ".hg" ];
        command = "${pkgs.clang-tools}/bin/clangd";
      };

      css = {
        filetypes = [ "css" ];
        roots = [ "package.json" ".git" ".hg" ];
        command = "${pkgs.nodePackages.vscode-css-languageserver-bin}/bin/vscode-css-languageserver";
        args = [ "--stdio" ];
      };

      html = {
        filetypes = [ "html" ];
        roots = [ "package.json" ".git" ".hg" ];
        command = "${pkgs.nodePackages.vscode-html-languageserver-bin}/bin/vscode-html-languageserver";
        args = [ "--stdio" ];
      };

      json = {
        filetypes = [ "json" ];
        roots = [ "package.json" ".git" ".hg" ];
        command = "${pkgs.nodePackages.vscode-json-languageserver-bin}/bin/vscode-json-languageserver";
        args = [ "--stdio" ];
      };

      nix = {
        filetypes = [ "nix" ];
        roots = [ "flake.nix" ".git" ".hg" ];
        command = "${pkgs.nixd}/bin/nixd";
      };

      yaml = {
        filetypes = [ "yaml" ];
        roots = [ ".git" ".hg" ];
        command = "${pkgs.nodePackages.yaml-language-server}/bin/yaml-language-server";
        args = [ "--stdio" ];
        # See https://github.com/redhat-developer/yaml-language-server#language-server-settings
        # Defaults are at https://github.com/redhat-developer/yaml-language-server/blob/master/src/yamlSettings.ts
        # settings.yaml.format.enable = true;
      };
    };
  };
}

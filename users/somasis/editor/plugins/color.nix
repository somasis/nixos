# Highlight color codes in buffers.
{ lib, pkgs, ... }: {
  programs.kakoune = {
    plugins = [
      (pkgs.kakouneUtils.buildKakounePluginFrom2Nix {
        pname = "palette";
        version = "unstable-2022-06-22";

        src = pkgs.fetchFromGitHub {
          owner = "Ordoviz";
          repo = "palette.kak";
          rev = "bbb179feae92e2d11ce9b3b0030f61cdfcfa35dd";
          hash = "sha256-dfp5iDaxwoD7H2XxpmpM/SztfCKODTJVmR04R+qHunM=";
        };
      })
    ];

    extraConfig = ''
      hook global WinCreate .* %{
          palette-enable
      }
    '';
  };
}

# Integrate yank with system clipboard.
{ pkgs, ... }: {
  programs.kakoune = {
    plugins = [
      (pkgs.kakouneUtils.buildKakounePluginFrom2Nix {
        pname = "clipb-kak";
        version = "2022-03-22";
        src = pkgs.fetchFromGitHub {
          owner = "NNBnh";
          repo = "clipb.kak";
          rev = "b640b2324ef21630753c4b42ddf31207233a98d2";
          hash = "sha256-KxoiZSGvhpNESwcIo/hxga8d7iyOSYpqBvcOej+NSec=";
        };
      })
    ];

    extraConfig =
      let
        xclip = "${pkgs.xclip}/bin/xclip";
      in
      ''
        clipb-detect
        clipb-enable

        set-option global clipb_multiple_selections "true"
        set-option global clipb_get_command "${xclip} -out -selection clipboard"
        set-option global clipb_set_command "${xclip} -in -selection clipboard"
      '';
  };
}

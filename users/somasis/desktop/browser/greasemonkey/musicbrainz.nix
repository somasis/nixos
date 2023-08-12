{ config
, pkgs
, inputs
, ...
}:
let
  nix-filter = inputs.nix-filter.lib;

  loujine = nix-filter {
    root = pkgs.fetchFromGitHub {
      owner = "loujine";
      repo = "musicbrainz-scripts";
      rev = "417dcdbff16f5e06d5d3f590549d559c34adb905";
      hash = "sha256-nJ26J2QZRG4HMIo7GM++vLLCQX+I0RoONykuGY6UHJA=";
    };
    include = [ (nix-filter.matchExt "user.js") ];
  };

  murdos = nix-filter {
    root = pkgs.fetchFromGitHub {
      owner = "murdos";
      repo = "musicbrainz-userscripts";
      rev = "a7139415ba3ffd55ec22f3af91cd8ec9b592ed36";
      hash = "sha256-7torWVYJuUqDDjxjHuVbu+Ku5q0V1Sb3m/OIwbf6HvE=";
    };
    include = [ (nix-filter.matchExt "user.js") ];
  };

  pathsFrom = storePath:
    assert (lib.isStorePath storePath);
    builtins.readDir storePath
  ;
  
in
{
  programs.qutebrowser.greasemonkey = [


    ((pkgs.fetchFromGitHub { owner = "jesus2099"; repo = "konami-command"; rev = "38dd9d1eb6cbf2d3b877922142acbd6691c7312b"; hash = "sha256-pel1IQZC+2Ntvkq1zMLq4DxCbVLaH0Yv+MT5TRmZHTc="; }) + /mb_AUTO-FOCUS-KEYBOARD-SELECT.user.js)
    ((pkgs.fetchFromGitHub { owner = "jesus2099"; repo = "konami-command"; rev = "38dd9d1eb6cbf2d3b877922142acbd6691c7312b"; hash = "sha256-pel1IQZC+2Ntvkq1zMLq4DxCbVLaH0Yv+MT5TRmZHTc="; }) + /mb_REDIRECT-WHEN-UNIQUE-RESULT.user.js)
    ((pkgs.fetchFromGitHub { owner = "jesus2099"; repo = "konami-command"; rev = "38dd9d1eb6cbf2d3b877922142acbd6691c7312b"; hash = "sha256-pel1IQZC+2Ntvkq1zMLq4DxCbVLaH0Yv+MT5TRmZHTc="; }) + /mb_ELEPHANT-EDITOR.user.js)
  ];
}

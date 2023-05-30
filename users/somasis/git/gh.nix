{ config
, nixosConfig
, pkgs
, ...
}: {
  programs.gh = {
    enable = true;
    settings = {
      git_protocol = "ssh";
      pager = "cat";
    };

    package = pkgs.symlinkJoin {
      name = "gh-with-pass";
      paths = [ pkgs.gh ];

      buildInputs = [ pkgs.makeWrapper ];
      postBuild = ''
        wrapProgram $out/bin/gh \
            --set-default GH_HOST "github.com" \
            --run ': "''${GH_TOKEN:=$(${config.programs.password-store.package}/bin/pass "${nixosConfig.networking.fqdnOrHostName}/gh/$GH_HOST/somasis")}"' \
            --run 'export GH_TOKEN'
      '';
    };
  };
}

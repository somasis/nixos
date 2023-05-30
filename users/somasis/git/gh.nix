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

    package = pkgs.wrapCommand {
      package = pkgs.gh;

      wrappers = [{
        setEnvironmentDefault.GH_HOST = "github.com";
        beforeCommand = [
          ''
            set +x
            : "''${GH_TOKEN:=$(${config.programs.password-store.package}/bin/pass "${nixosConfig.networking.fqdnOrHostName}/gh/$GH_HOST/''${USER:-$(id -un)}")}"
            export GH_TOKEN
          ''
        ];
      }];
    };
  };
}

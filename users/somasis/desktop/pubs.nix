{ config
, lib
, ...
}: {
  programs.pubs = {
    enable = true;
    extraConfig = lib.generators.toINI { } {
      main = {
        pubsdir = "${config.home.homeDirectory}/study/pubs";
        docsdir = "${config.home.homeDirectory}/study/doc";

        doc_add = "move";
      };

      plugins.active = "alias";
    };
  };
}

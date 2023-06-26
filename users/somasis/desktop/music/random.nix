{ lib
, pkgs
, config
, ...
}:
let
  inherit (config.lib.somasis) commaList;
  inherit (lib.generators) mkKeyValueDefault toINI;
in
{
  home.packages = [
    (pkgs.symlinkJoin {
      name = "mpd-sima-with-completion";

      paths = [ pkgs.mpd-sima ];

      postBuild = ''
        install -d $out/share/bash-completion/completions
        install -m0755 \
            ${pkgs.mpd-sima.src}/data/bash/completion.sh \
            $out/share/bash-completion/completions/mpd-sima
      '';
    })
  ];

  cache.directories = [ "share/mpd_sima" ];

  xdg.configfile."mpd_sima/mpd_sima.cfg".source = lib.generators.toini
    {
      listsAsDuplicateKeys = false;
      mkKeyValue = k: v:
        if lib.isList v then
          mkKeyValueDefault { } "=" k (commaList v)
        else
          mkKeyValueDefault { } "=" k v
      ;
    }
    {
      sima = {
        internal = [ "Crop" "Lastfm" "Random" ];
        queue_length = 6;
      };
      crop.consume = 10;
      lastfm = {
        queue_mode = "track";
        single_album = false;
        track_to_add = 3;
      };
      random.track_to_add = 3;
    }
  ;

  systemd.user.services.mpd-sima = {
    Unit = {
      Description = pkgs.mpd-sima.meta.description;
      BindsTo = [ "mpd.service" ];
      After = [ "mpd.service" ];
    };

    Service = {
      Type = "simple";
      ExecStart = [ "${pkgs.mpd-sima}/bin/mpd-sima" ];
    };
  };
}

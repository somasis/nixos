{ pkgs
, lib
, ...
}:
{
  somasis.tunnels.tunnels = {
    "somasis@lacan.somas.is:syncthing" = {
      name = "syncthing";
      port = 8385;
      remote = "somasis@lacan.somas.is";
    };

    "somasis@genesis.whatbox.ca:syncthing" = {
      name = "syncthing";
      port = 10730;
      remote = "somasis@genesis.whatbox.ca";
    };

    "tv@spinoza.7596ff.com:syncthing" = {
      name = "syncthing";
      port = 45435;
      remote = "tv@spinoza.7596ff.com";
      remotePort = 8384;
    };

    "somasis@spinoza.7596ff.com:syncthing" = {
      name = "syncthing";
      port = 45739;
      remote = "somasis@spinoza.7596ff.com";
    };
  };

  # services.syncthing.tray = {
  #   enable = false;
  #   package = pkgs.syncthingtray-minimal;
  # };

  # persist.files = [ "etc/syncthingtray.ini" ];
}

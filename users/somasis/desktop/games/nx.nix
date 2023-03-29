{ config
, pkgs
, ...
}:
let
  inherit (pkgs.nodePackages) nxapi;
  # nxapiProxy = "127.0.0.1:8472";
in
{
  home.persistence."/persist${config.home.homeDirectory}".directories = [ "share/nxapi-nodejs" ];
  home.packages = [
    nxapi
    # (pkgs.symlinkJoin {
    #   name = "nxapi-final";

    #   buildInputs = [ pkgs.makeWrapper ];
    #   paths = [ nxapi ];

    #   postBuild = ''
    #     wrapProgram $out/bin/nxapi \
    #         --add-flags '--user <(
    #   '';
    # })
  ];

  # systemd.user.services = {
  #   nxapi-presence = {
  #     Service = {
  #       Type = "simple";
  #       ExecStart = ''
  #         ${nxapi}/bin/nxapi nso http-server --listen "${nxapiPresence}" --update-interval 60
  #       '';
  #     };
  #   };
  #   nxapi-presence = {
  #     Service = {
  #       Type = "simple";
  #       ExecStart = ''
  #         ${nxapi}/bin/nxapi nso presence --user 
  #       ''
  #         };
  #     }
}

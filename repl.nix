{ flake
, hostName
, userName
}:
let
  currentFlake = builtins.getFlake flake;

  currentHost = currentFlake.nixosConfigurations."${hostName}";
  currentUser = currentHost.config.home-manager.users."${userName}";
in
{
  inputs = currentFlake.inputs;
  outputs = currentFlake.outputs;

  "${hostName}" = currentHost;

  config = currentHost.pkgs.lib.recursiveUpdate
    currentHost.config
    { hm = builtins.removeAttrs currentUser [ "lib" ]; };

  lib = currentHost.pkgs.lib.recursiveUpdate
    currentHost.pkgs.lib
    { hm = currentUser.lib; };
} // currentFlake

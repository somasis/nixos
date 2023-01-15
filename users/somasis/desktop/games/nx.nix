{ config
, pkgs
, ...
}:
{
  home.packages = [ pkgs.nodePackages.nxapi ];
}

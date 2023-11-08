{ pkgs
, nixpkgs
, ...
}:
let
  nixpkgs-manual = pkgs.callPackage "${nixpkgs}/doc" { };
in
{
  documentation = {
    info.enable = false;
    doc.enable = false;
    dev.enable = true;
    nixos = {
      enable = true; # Provides `nixos-help`.
      includeAllModules = true;
    };

    man = {
      enable = true;
      generateCaches = true;
      man-db.enable = false;
      mandoc.enable = true;
    };
  };

  # environment.systemPackages = [
  #   nixpkgs-manual
  #   (pkgs.writeShellScriptBin "nixpkgs-help" ''
  #     exec "''${BROWSER:-xdg-open}" "file://${nixpkgs-manual}/share/doc/nixpkgs/manual.html"
  #   '')
  # ];
}

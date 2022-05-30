{ nixosConfig, config, pkgs, ... }:
let
  nix = "${nixosConfig.nix.package}/bin/nix";
  nixLocateCmd = "${config.programs.nix-index.package}/bin/nix-locate";
in
{
  home.packages = [
    (pkgs.writeShellScriptBin ",m" ''
      WINDOWID=''${WINDOWID:-$(xdotool getwindowfocus)}

      p=$(
          ${nixLocateCmd} --at-root -r -t r -t s -1 "/share/man/[^/]+/$1\.[^\.]+(\.gz)?$" \
              | sort -u \
              | ''${DMENU:-dmenu} -w "$WINDOWID" -n -p ",m"
      )

      p=$(${nix} eval --raw "nixpkgs#$p")
      p=$(${nix}-store -r "$p")

      export MANPATH="$p/share/man"
      exec man "$1"
    '')
  ];
}

{ pkgs, lib, config, ... }:
let
  kdeconnect = pkgs.writeShellScript "kdeconnect" ''
    export PATH=${lib.makeBinPath [ pkgs.plasma5Packages.kdeconnect-kde pkgs.xe ]}:$PATH

    while [ $# -gt 0 ]; do
        kdeconnect-cli -a --id-only \
            | xe -j0 kdeconnect-cli -d {} --share "$1"
        shift
    done
  '';
in
{
  services.kdeconnect.enable = true;
  home.persistence."/persist${config.home.homeDirectory}".directories = [ "etc/kdeconnect" ];

  programs.qutebrowser.keyBindings.normal."<z><k>" = "spawn -u ${kdeconnect}";
}

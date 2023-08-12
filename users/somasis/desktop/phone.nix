{ pkgs
, config
, osConfig
, lib
, ...
}:
let
  kdeconnectShare = pkgs.writeShellScript "kdeconnect-share" ''
    PATH=${lib.makeBinPath [ pkgs.plasma5Packages.kdeconnect-kde pkgs.xe ]}:"$PATH"
    while [ $# -gt 0 ]; do
        kdeconnect-cli -a --id-only \
            | xe -j0 kdeconnect-cli -d {} --share "$1"
        shift
    done
  '';
in
{
  services.kdeconnect = {
    enable = true;
    indicator = true;
  };

  xdg.configFile."kdeconnect/config".text = lib.generators.toINI { } {
    General.name = "${config.home.username}@${osConfig.networking.fqdnOrHostName}";
  };

  persist.directories = [{
    # bindfs must be used because of the configFile we're making in the directory
    method = "bindfs";
    directory = "etc/kdeconnect";
  }];

  programs.qutebrowser = {
    aliases.kdeconnect = "spawn -u ${kdeconnectShare}";
    keyBindings.normal."zk" = "kdeconnect {url}";
  };
}

{ pkgs
, config
, nixosConfig
, lib
, ...
}:
let
  kdeconnectShare = pkgs.writeShellApplication {
    name = "kdeconnect-share";

    runtimeInputs = [
      pkgs.plasma5Packages.kdeconnect-kde
      pkgs.xe
    ];

    text = ''
      while [ $# -gt 0 ]; do
          kdeconnect-cli -a --id-only \
              | xe -j0 kdeconnect-cli -d {} --share "$1"
          shift
      done
    '';
  };
in
{
  services.kdeconnect.enable = true;

  xdg.configFile = {
    # "kdeconnect/.keep".source = builtins.toFile "keep" "";

    "kdeconnect/config".text = lib.generators.toINI { } {
      General.name = "${config.home.username}@${nixosConfig.networking.fqdnOrHostName}";
    };
  };


  home.persistence."/persist${config.home.homeDirectory}".directories = [ "etc/kdeconnect" ];

  programs.qutebrowser = {
    aliases.kdeconnect = "spawn -u ${kdeconnectShare}";
    keyBindings.normal."zk" = "kdeconnect";
  };
}

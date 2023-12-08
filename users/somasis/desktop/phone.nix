{ pkgs
, config
, osConfig
, lib
, ...
}:
assert osConfig.programs.kdeconnect.enable;
let
  kdeconnect = osConfig.programs.kdeconnect.package;

  kdeconnectShare = pkgs.writeShellScript "kdeconnect-share" ''
    PATH=${lib.makeBinPath [ kdeconnect pkgs.xe ]}:"$PATH"
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
    # indicator = true;
  };

  xdg.configFile."kdeconnect/config".text = lib.generators.toINI { } {
    General.name = "${config.home.username}@${osConfig.networking.fqdnOrHostName}";
  };

  persist.directories = [{
    # bindfs must be used because of the configFile we're making in the directory
    method = "bindfs";
    directory = config.lib.somasis.xdgConfigDir "kdeconnect";
  }];

  programs.qutebrowser = {
    aliases.kdeconnect = "spawn -u ${kdeconnectShare}";
    keyBindings.normal."zk" = "kdeconnect {url}";
  };

  # Set up vdirsyncer<->kdeconnect integration for `kdeconnect-sms`.
  # Seems to work surprisingly well?
  systemd.user.services.kdeconnect.Service.ExecStartPost =
    lib.mkIf
      (config.programs.vdirsyncer.enable && config.accounts.contact.accounts != { }) [
      (
        let
          collections =
            lib.flatten (
              map
                (account:
                  map
                    (collection: ''
                      if [ -d "$dir" ]; then rm -fr "$dir"; fi
                      ln -sf ${lib.escapeShellArg "${config.accounts.contact.basePath}/${account}/${collection}"} "$dir"
                    '')
                    config.accounts.contact.accounts."${account}".vdirsyncer.collections
                )
                (builtins.attrNames config.accounts.contact.accounts)
            )
          ;
        in
        pkgs.writeShellScript "kdeconnect-vdirsyncer" ''
          PATH=${lib.makeBinPath [ pkgs.coreutils pkgs.kdeconnect ]}

          : "''${XDG_DATA_HOME:=$HOME/.local/share}"

          kpeoplevcard_dir="$XDG_DATA_HOME/kpeoplevcard"
          mkdir -p "$kpeoplevcard_dir"

          kdeconnect-cli --list-devices --id-only \
              | while IFS= read -r device; do
                  dir="$kpeoplevcard_dir/kdeconnect-$device"
                  if ! [ -L "$dir" ]; then
                      ${lib.concatLines collections}
                  fi
              done
        ''
      )
    ];
}

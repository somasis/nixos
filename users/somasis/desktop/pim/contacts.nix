{ config
, osConfig
, lib
, pkgs
, ...
}:
let
  remoteFastmail = type: userName: {
    inherit type;
    url = "https://${type}.messagingengine.com";
    inherit userName;
    passwordCommand = [
      (toString (pkgs.writeShellScript "password-command" ''
        ${config.programs.password-store.package}/bin/pass \
            ${lib.escapeShellArg osConfig.networking.fqdnOrHostName}/vdirsyncer/${lib.escapeShellArg userName}
      ''))
    ];
  };
in
rec {
  accounts.contact = {
    basePath = "contacts";

    accounts = {
      contacts = { name, ... }: {
        local = {
          type = "filesystem";
          fileExt = ".vcf";
        };

        remote = remoteFastmail "carddav" "kylie@somas.is";

        vdirsyncer = {
          enable = true;

          collections = [ "Default" ];

          conflictResolution = "remote wins";

          metadata = [ "displayname" ];
        };
      };
    };
  };

  # use accounts.* without config so that we get it before the path is made absolute
  persist.directories = lib.mkMerge [
    (map
      (account: { method = "symlink"; directory = "${accounts.contact.basePath}/${account}"; })
      (builtins.attrNames accounts.contact.accounts)
    )
  ];

  home.packages = [ pkgs.khard ];
}

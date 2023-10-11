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

  # Uses configobj, like vdirsyncer.
  # <https://configobj.readthedocs.io/en/latest/configobj.html#the-config-file-format>
  xdg.configFile."khard/khard.conf".text =
    let
      # Generate collection configurations.
      #
      # ex. ''
      # [[contacts_Default]]
      # path = "/home/somasis/contacts/contacts/Default"
      # ''

      collections =
        lib.concatLines (
          lib.flatten
            (lib.mapAttrsToList
              (accountName: accountValue:
                map
                  (collection:
                    ''
                      [[${accountName}_${collection}]]
                      path = "${lib.escape [ "\"" ] "${config.accounts.contact.basePath}/${accountName}/${collection}"}"
                    ''
                  )
                  accountValue.vdirsyncer.collections
              )
              config.accounts.contact.accounts
            )
        )
      ;

    in
    ''
      [general]
      default_action = list

      [addressbooks]
      ${collections}

      [contact table]
      display = formatted_name

      # Use ISO dates (YYYY-MM-DD)
      localize_dates = no

      preferred_email_address_type = pref, work, home
      preferred_phone_number_type = pref, main, voice, cell, home

      group_by_addressbook = no
      reverse = no
      sort = last_name

      show_kinds = no
      show_nicknames = yes
      show_uids = no

      [vcard]

      # 3.0 is the version used by Fastmail.
      preferred_version = 3.0

      private_objects = Anniversary, Discord, Matrix, Pronouns, Social-Profile, Tumblr, Twitter

      search_in_source_files = no

      skip_unparsable = yes
    '';
}

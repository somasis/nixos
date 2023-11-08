{ config
, osConfig
, lib
, pkgs
, ...
}:
let
  fastmail = type: userName: {
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

        remote = fastmail "carddav" "kylie@somas.is";

        vdirsyncer = {
          enable = true;
          collections = [ "Default" ];
          metadata = [ "displayname" "color" ];
          conflictResolution = "remote wins";
        };

        khard.enable = true;
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

  programs.khard = {
    enable = true;

    settings = {
      general.default_action = "list";

      "contact table" = {
        display = "formatted_name";

        # Use ISO dates (YYYY-MM-DD)
        localize_dates = false;

        preferred_email_address_type = [ "pref" "work" "home" ];
        preferred_phone_number_type = [ "pref" "main" "voice" "cell" "home" ];

        group_by_addressbook = false;
        reverse = false;
        sort = "last_name";

        show_kinds = false;
        show_nicknames = true;
        show_uids = false;
      };

      vcard = {
        # 3.0 is the version used by Fastmail.
        preferred_version = "3.0";

        private_objects = [ "Anniversary" "Discord" "Matrix" "Pronouns" "Social-Profile" "Tumblr" "Twitter" ];

        search_in_source_files = false;

        skip_unparsable = true;
      };
    };
  };
}

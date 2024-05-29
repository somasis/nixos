{ self
, inputs
, nixpkgs
, overlays
, ...
}:
nixpkgs.lib.nixosSystem {
  inherit (nixpkgs) lib;

  specialArgs = { inherit self inputs nixpkgs; };

  modules = with self; with inputs; [
    ({ self, inputs, lib, config, ... }: {
      nixpkgs = {
        config = {
          allowUnfree = true;
          # contentAddressedByDefault = true;
        };

        # localSystem = {
        #   isx86_64 = true;
        #   isEfi = true;
        #   isLinux = true;
        #   isMusl = true;
        #   useLLVM = true;
        #   system = "x86_64-unknown-linux-musl";
        # };

        localSystem = {
          system = "x86_64-linux";
          isLinux = true;
          isx86_64 = true;
          # isMusl = true;
          # isLLVM = true;
        };
        # hostPlatform = "x86_64-linux";

        inherit overlays;
      };
    })

    # Modules from elsewhere
    nixosModules.lib
    impermanence.nixosModules.impermanence
    nixos-hardware.nixosModules.framework-12th-gen-intel
    nix-index-database.nixosModules.nix-index

    # My modules
    nixosModules.impermanence

    ({ config
     , pkgs
     , lib
     , ...
     }: {
      imports = [
        ./hardware
        ./networking

        ./backup.nix
        ./boot.nix
        ./console.nix
        ./documentation.nix
        ./filesystems.nix
        ./fonts.nix
        ./games.nix
        ./locale.nix
        ./nix.nix
        ./power.nix
        ./security.nix
        ./ssh.nix
        ./uptimed.nix
        ./users.nix
        ./wine.nix
      ];

      persist = {
        hideMounts = true;
        directories = [ "/etc/nixos" ];
      };

      cache = {
        hideMounts = true;

        directories = [
          "/var/lib/systemd/timers"
          "/var/lib/systemd/backlight"
          "/var/lib/systemd/linger"
        ];
        files = [ "/var/lib/systemd/random-seed" ];
      };

      log = {
        hideMounts = true;

        directories = [
          "/var/lib/systemd/catalog"
          "/var/lib/systemd/coredump"
          { directory = "/var/log/journal"; user = "root"; group = "systemd-journal"; mode = "2755"; }
        ];
        files = [
          "/var/log/btmp"
          "/var/log/lastlog"
          "/var/log/wtmp"
          "/etc/machine-id"
        ];
      };

      services.xserver.enable = true;

      # Use dbus-broker since it's faster.
      services.dbus.implementation = "broker";

      services.flatpak.enable = true;
      xdg.portal = {
        enable = true;
        config.bspwm.default = "gtk";
        extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
        configPackages = [ pkgs.xdg-desktop-portal-gtk ];
      };

      programs.command-not-found.enable = false;
      programs.nano.enable = false;

      environment = {
        systemPackages = [
          # Necessary for `nixos-rebuild`'s git stuff
          pkgs.extrace
          pkgs.git
          pkgs.gparted

          pkgs.notify-send-all
        ];

        variables = {
          XDG_BIN_HOME = "\${HOME}/local/bin";
          XDG_CACHE_HOME = "\${HOME}/var/cache";
          XDG_CONFIG_HOME = "\${HOME}/etc";
          XDG_DATA_HOME = "\${HOME}/share";
          XDG_LIB_HOME = "\${HOME}/local/lib";
          XDG_STATE_HOME = "\${HOME}/var/lib";
        };
      };

      security.wrappers.extrace = {
        source = "${pkgs.extrace}/bin/extrace";
        capabilities = "cap_net_admin+ep";
        owner = "root";
        group = "root";
      };

      # Force is required because services.xserver forces xdg.*.enable to true.
      xdg.autostart.enable = lib.mkForce false;
      xdg.menus.enable = lib.mkForce true;
      xdg.mime.enable = lib.mkForce true; # TODO
      xdg.sounds.enable = lib.mkForce false;

      programs.bash = {
        enableCompletion = true;
        enableLsColors = false;
      };

      environment.pathsToLink =
        lib.optional config.programs.bash.enableCompletion "/share/bash-completion"
        ++ lib.optionals config.xdg.portal.enable [ "/share/xdg-desktop-portal" "/share/applications" ]
      ;

      services.gvfs.enable = true;
      services.tumbler.enable = true;
      programs.dconf.enable = true;

      system.stateVersion = "22.11";
    })

    home-manager.nixosModules.default
    {
      home-manager = {
        verbose = true;

        useGlobalPkgs = false;
        useUserPackages = true;

        extraSpecialArgs = { inherit self inputs nixpkgs; };

        sharedModules =
          # Modules from elsewhere
          (with inputs; [
            impermanence.nixosModules.home-manager.impermanence
            nix-index-database.hmModules.nix-index
          ])
          # My modules
          ++ (with self; [
            nixosModules.lib
            homeManagerModules.default
          ])
        ;

        users.somasis = { pkgs, ... }: {
          imports = [
            ../../users/somasis
            ../../users/somasis/desktop
          ];
        };
      };
    }
  ];
}

{ inputs
, nixpkgs
, ...
}:
let
  system = "x86_64-linux";
in
nixpkgs.lib.nixosSystem {
  inherit (nixpkgs) lib;

  specialArgs = { inherit inputs nixpkgs; };

  modules = with inputs; [
    ({ lib, ... }: {
      nixpkgs = {
        config.allowUnfree = true;

        localSystem = {
          inherit system;
          isLinux = true;
          isx86_64 = true;

          # isMusl = true;
          # useLLVM = true;
        };

        overlays = [
          (final: prev: {
            stable = inputs.nixpkgsStable.legacyPackages."${system}";
          })
        ];
      };
    })

    disko.nixosModules.disko
    impermanence.nixosModules.impermanence
    nixos-hardware.nixosModules.framework

    nix-index-database.nixosModules.nix-index

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
        ./filesystems.nix
        ./fonts.nix
        ./games.nix
        # ./harden.nix
        ./locale.nix
        ./nix.nix
        ./power.nix
        ./security.nix
        ./ssh.nix
        ./uptimed.nix
        ./users.nix
        ./wine.nix
      ];

      environment.persistence."/persist" = {
        hideMounts = true;
        directories = [ "/etc/nixos" ];
      };

      environment.persistence."/cache" = {
        hideMounts = true;
        directories = [
          "/var/lib/systemd/timers"
          "/var/lib/systemd/timesync"
          "/var/lib/systemd/backlight"
        ];
        files = [ "/var/lib/systemd/random-seed" ];
      };

      environment.persistence."/log" = {
        hideMounts = true;
        directories = [
          "/var/lib/systemd/catalog"
          "/var/lib/systemd/coredump"
          "/var/log/journal"
        ];
        files = [
          "/var/log/btmp"
          "/var/log/lastlog"
          "/var/log/wtmp"
        ];
      };

      services.journald.console = "/dev/tty12";

      services.xserver.enable = true;

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
          mandoc = {
            enable = true;
            # manPath = [ "share/man/tok" ];
          };
        };
      };

      programs.command-not-found.enable = false;
      environment = {
        defaultPackages = [ ];

        systemPackages = [
          # Necessary for `nixos-rebuild`'s git stuff
          pkgs.git

          pkgs.gparted
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

      # Force is required because services.xserver forces xdg.*.enable to true.
      xdg = lib.mkForce {
        autostart.enable = false;
        menus.enable = true;
        mime.enable = true; # TODO
        sounds.enable = false;
        portal.enable = false;
      };

      programs.bash = {
        enableCompletion = true;
        enableLsColors = false;
      };

      # services.gvfs.enable = lib.mkForce false;
      programs.dconf.enable = true;

      system.stateVersion = "22.11";
    })

    home-manager.nixosModules.default
    {
      home-manager = {
        verbose = true;

        useGlobalPkgs = true;
        useUserPackages = true;

        extraSpecialArgs = { inherit inputs nixpkgs; };

        sharedModules = with inputs; [
          impermanence.nixosModules.home-manager.impermanence
          nix-index-database.hmModules.nix-index
          # hyprland.homeManagerModules.default
        ];

        users.somasis.imports = [
          ../../users/somasis
          ../../users/somasis/desktop
        ];
      };
    }
  ];
}

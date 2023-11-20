{ self
, inputs
, nixpkgs
, overlays
, ...
}:
let prevOverlays = overlays; in
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

        localSystem = {
          system = "x86_64-linux";
          isLinux = true;
          isx86_64 = true;

          # isMusl = true;
          # isLLVM = true;
        };

        overlays =
          prevOverlays
          ++ [
            # Fix `nixos-option` to work with Flakes.
            # Based on <https://github.com/NixOS/nixpkgs/issues/97855#issuecomment-1075818028>.
            (final: prev: {
              nixos-option =
                let
                  prefix =
                    ''(import ${inputs.flake-compat} { src = /etc/nixos; }).defaultNix.nixosConfigurations.${lib.strings.escapeNixString config.networking.hostName}'';
                in
                prev.wrapCommand {
                  package = prev.nixos-option;

                  wrappers = [{
                    prependFlags = lib.escapeShellArgs (
                      [ ]
                      ++ [ "--config_expr" "${prefix}.config" ]
                      ++ [ "--options_expr" "${prefix}.options" ]
                    );
                  }];
                };
            })
          ]
        ;
      };
    })

    nixosModules.lib

    impermanence.nixosModules.impermanence
    nixosModules.impermanence

    nixos-hardware.nixosModules.framework-11th-gen-intel

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
          "/var/log/journal"
        ];
        files = [
          "/var/log/btmp"
          "/var/log/lastlog"
          "/var/log/wtmp"
        ];
      };

      services.xserver.enable = true;

      programs.command-not-found.enable = false;
      environment = {
        defaultPackages = [ ];
        etc."nanorc".enable = false;

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
      xdg = lib.mkForce {
        autostart.enable = false;
        menus.enable = true;
        mime.enable = true; # TODO
        sounds.enable = false;
      };

      programs.bash = {
        enableCompletion = true;
        enableLsColors = false;
      };

      environment.pathsToLink = lib.optional config.programs.bash.enableCompletion "/share/bash-completion";

      services.gvfs.enable = true;
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

        sharedModules = with self; with inputs; [
          nixosModules.lib
          nixosModules.home-manager.theme

          impermanence.nixosModules.home-manager.impermanence
          nixosModules.home-manager.impermanence

          nix-index-database.hmModules.nix-index
        ];

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

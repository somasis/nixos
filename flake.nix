{
  description = "somas.is";

  inputs = {
    # avatarSomasis = {
    #   # jq -nrR \
    #   #     --arg hash "$(printf '%s' 'kylie@somas.is' | md5sum | cut -d ' ' -f1)" \
    #   #     --arg size 512 \
    #   #     --arg fallback "https://avatars.githubusercontent.com/${USER}?size=512" \
    #   #     '"url = \"https://www.gravatar.com/avatar/\($hash)?s=\($size)&d=\($fallback | @uri)\";"'
    #   #     '
    #   flake = false;
    #   url = "https://www.gravatar.com/avatar/a187e38560bb56f5231cd19e45ad80f6?s=512&d=https%3A%2F%2Favatars.githubusercontent.com%2Fsomasis%3Fsize%3D512";
    # };

    flake.url = "github:gytis-ivaskevicius/flake-utils-plus";

    nixos.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    nixosStable.url = "github:nixos/nixpkgs?ref=nixos-22.11";
    nixosHardware.url = "github:nixos/nixos-hardware";

    lollypops.url = "github:pinpox/lollypops";
    lollypops.inputs.nixpkgs.follows = "nixos";

    impermanence.url = "github:nix-community/impermanence";
    # disko = {
    #   url = "github:nix-community/disko";
    #   inputs.nixpkgs.follows = "nixos";
    # };

    homeManager.url = "github:nix-community/home-manager";
    homeManager.inputs.nixpkgs.follows = "nixos";

    nixMinecraft.url = "github:12Boti/nix-minecraft";
    nixMinecraft.inputs.nixpkgs.follows = "nixos";

    # erosanix.url = "github:emmanuelrosa/erosanix";
    # erosanix.inputs.nixpkgs.follows = "nixos";

    plasmaManager.url = "github:pjones/plasma-manager";
    plasmaManager.inputs.nixpkgs.follows = "nixos";
    plasmaManager.inputs.home-manager.follows = "homeManager";

    catgirl.flake = false;
    catgirl.url = "git+https://git.causal.agency/catgirl?ref=somasis/tokipona";
    dmenu-flexipatch.flake = false;
    dmenu-flexipatch.url = "github:bakkeby/dmenu-flexipatch";
    mblaze.flake = false;
    mblaze.url = "github:leahneukirchen/mblaze";
    sbase.flake = false;
    sbase.url = "git://git.suckless.org/sbase";
    ubase.flake = false;
    ubase.url = "github:michaelforney/ubase";

    replugged.url = "github:LunNova/replugged-nix-flake";
    replugged.inputs.nixpkgs.follows = "nixos";

    repluggedPluginBetterCodeblocks.flake = false;
    repluggedPluginBetterCodeblocks.url = "github:replugged-org/better-codeblocks";
    repluggedPluginBotInfo.flake = false;
    repluggedPluginBotInfo.url = "github:IRONM00N/bot-details";
    repluggedPluginCanaryLinks.flake = false;
    repluggedPluginCanaryLinks.url = "github:asportnoy/CanaryLinks";
    repluggedPluginChannelTyping.flake = false;
    repluggedPluginChannelTyping.url = "github:powercord-community/channel-typing";
    repluggedPluginClickableEdits.flake = false;
    repluggedPluginClickableEdits.url = "github:replugged-org/clickable-edits";
    repluggedPluginCutecord.flake = false;
    repluggedPluginCutecord.url = "github:powercord-community/cutecord";
    repluggedPluginEmojiUtility.flake = false;
    repluggedPluginEmojiUtility.url = "github:replugged-org/emoji-utility";
    repluggedPluginPersistSettings.flake = false;
    repluggedPluginPersistSettings.url = "github:venplugs/persistsettings";
    repluggedPluginSitelenPona.flake = false;
    repluggedPluginSitelenPona.url = "github:dzshn/powercord-sitelen-pona";
    repluggedPluginThemeToggler.flake = false;
    repluggedPluginThemeToggler.url = "github:redstonekasi/theme-toggler";
    repluggedPluginTimestampSender.flake = false;
    repluggedPluginTimestampSender.url = "github:Anime-Forevere/Timestamp-Sender";
    repluggedPluginTokiPona.flake = false;
    repluggedPluginTokiPona.url = "github:somasis/discord-tokipona";
    repluggedPluginWordFilter.flake = false;
    repluggedPluginWordFilter.url = "github:A-Trash-Coder/wordfilter";
    repluggedThemeCustom.flake = false;
    repluggedThemeCustom.url = "path:/home/somasis/src/discord-theme-custom";
    repluggedThemeIrc.flake = false;
    repluggedThemeIrc.url = "github:somasis/discord-theme-irc";

    hyprland.flake = true;
    hyprland.url = "github:hyprwm/Hyprland";
    hyprland.inputs.nixpkgs.follows = "nixos";

    adblockEasyList = {
      flake = false;
      url = "github:easylist/easylist";
    };

    adblockEasyListSpanish = {
      flake = false;
      url = "github:easylist/easylistspanish";
    };

    adblockAntiAdblockFilters = {
      flake = false;
      url = "github:easylist/antiadblockfilters";
    };

    uBlock = {
      flake = false;
      url = "github:uBlockOrigin/uAssets";
    };

    adblockHosts.flake = false;
    adblockHosts.url = "github:StevenBlack/hosts";
  };

  outputs = inputs@{ self, flake, ... }: flake.lib.mkFlake {
    inherit self inputs;

    supportedSystems = with flake.lib.system; [ x86_64-linux ];
    channelsConfig.allowUnfree = true;

    sharedOverlays = [ flake.outputs.overlay ];

    hostDefaults = {
      channelName = "nixosStable";
      system = flake.lib.system.x86_64-linux;

      extraArgs = { inherit flake inputs; };

      modules = with inputs; [
        { nix.registry.nixpkgs.flake = inputs.nixosStable; }

        lollypops.nixosModules.lollypops

        impermanence.nixosModules.impermanence

        {
          nix = {
            generateRegistryFromInputs = true;
            linkInputs = true;

            settings = {
              experimental-features = [
                "nix-command"
                "flakes"
              ];
            };

            # Disable $NIX_PATH entirely. Only flake-enabled commands.
            nixPath = [ ];
          };
        }

        # {
        #   users = {
        #     users.somasis = {
        #       group = "somasis";
        #       extraGroups = [ "users" ];
        #       isNormalUser = true;
        #     };
        #     groups.somasis = { };
        #   };
        # }

        homeManager.nixosModules.home-manager
        {
          home-manager = {
            useGlobalPkgs = true;
            useUserPackages = true;

            sharedModules = with inputs; [
              impermanence.nixosModules.home-manager.impermanence

              { home.enableNixpkgsReleaseCheck = true; }
            ];

            extraSpecialArgs = { inherit inputs; };
          };
        }
      ];
    };

    hosts = {
      ilo = {
        channelName = "nixos";

        modules = with inputs; [
          { nix.registry.nixpkgs.flake = inputs.nixos; }

          nixosHardware.nixosModules.framework

          ./hosts/ilo.somas.is

          # disko.nixosModules.disko

          homeManager.nixosModules.home-manager
          {
            home-manager = {
              sharedModules = with inputs; [
                # plasmaManager.homeManagerModules.plasma-manager
                # nixMinecraft.nixosModules.home-manager.minecraft
                hyprland.homeManagerModules.default
              ];

              verbose = true;

              users.somasis = {
                imports = [
                  ./users/somasis
                  ./users/somasis/desktop
                ];
              };
            };
          }
        ];
      };

      nixos = {
        channelName = "nixosStable";

        modules = with inputs; [
          { nix.registry.nixpkgs.flake = inputs.nixosStable; }
          ./hosts/nixos.somas.is

          homeManager.nixosModules.home-manager
          {
            home-manager.users.somasis = {
              imports = [
                ./users/somasis
              ];
            };
          }
        ];
      };
    };

    apps."x86_64-linux".default = inputs.lollypops.apps."x86_64-linux".default { configFlake = self; };
  };
}

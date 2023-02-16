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

    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    nixpkgsStable.url = "github:nixos/nixpkgs?ref=nixos-22.11";

    nixosHardware.url = "github:nixos/nixos-hardware";

    impermanence.url = "github:nix-community/impermanence";
    # disko = {
    #   url = "github:nix-community/disko";
    # };

    homeManager.url = "github:nix-community/home-manager";
    homeManager.inputs.nixpkgs.follows = "nixpkgs";

    # nixMinecraft.url = "github:12Boti/nix-minecraft";

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
    replugged.inputs.nixpkgs.follows = "nixpkgs";

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
    hyprland.inputs.nixpkgs.follows = "nixpkgs";

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
      channelName = "nixpkgsStable";
      system = flake.lib.system.x86_64-linux;

      extraArgs = { inherit flake inputs; };

      modules = with inputs; [
        impermanence.nixosModules.impermanence

        ({ config, lib, ... }: {
          nix = {
            registry = lib.mapAttrs (_: value: { flake = value; }) inputs;
            nixPath = lib.mapAttrsToList (key: value: "${key}=${value.to.path}") config.nix.registry;

            settings.experimental-features = [ "nix-command" "flakes" ];
          };

          nixpkgs.overlays = [
            (final: _prev: {
              unstable = inputs.nixpkgs.legacyPackages.${final.system};
            })
          ];
        })

        homeManager.nixosModules.default
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

    hosts.ilo = {
      channelName = "nixpkgs";

      modules = with inputs; [
        nixosHardware.nixosModules.framework

        ./hosts/ilo.somas.is

        # disko.nixosModules.disko

        homeManager.nixosModules.default
        {
          home-manager = {
            sharedModules = with inputs; [
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
  };
}

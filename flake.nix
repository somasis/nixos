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

    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    nixpkgsStable.url = "github:nixos/nixpkgs?ref=nixos-23.05";

    nixos-hardware.url = "github:nixos/nixos-hardware";
    lanzaboote.url = "github:nix-community/lanzaboote";
    lanzaboote.inputs.nixpkgs.follows = "nixpkgs";

    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    # Use a pre-built nix-index database
    nix-index-database.url = "github:Mic92/nix-index-database";
    nix-index-database.inputs.nixpkgs.follows = "nixpkgs";

    impermanence.url = "github:nix-community/impermanence";

    disko.url = "github:nix-community/disko";
    disko.inputs.nixpkgs.follows = "nixpkgs";

    nix-filter.url = "github:numtide/nix-filter";

    catgirl.flake = false;
    catgirl.url = "git+https://git.causal.agency/catgirl?ref=somasis/tokipona";
    dmenu-flexipatch.flake = false;
    dmenu-flexipatch.url = "github:bakkeby/dmenu-flexipatch";
    lemonbar.flake = false;
    lemonbar.url = "github:drscream/lemonbar-xft/xft-port";
    mblaze.flake = false;
    mblaze.url = "github:leahneukirchen/mblaze";
    sbase.flake = false;
    sbase.url = "git://git.suckless.org/sbase";
    ubase.flake = false;
    ubase.url = "github:michaelforney/ubase";

    # replugged.url = "github:LunNova/replugged-nix-flake";
    # replugged.inputs.nixpkgs.follows = "nixpkgs";
    # repluggedPluginBetterCodeblocks.flake = false;
    # repluggedPluginBetterCodeblocks.url = "github:replugged-org/better-codeblocks";
    # repluggedPluginBotInfo.flake = false;
    # repluggedPluginBotInfo.url = "github:IRONM00N/bot-details";
    # repluggedPluginCanaryLinks.flake = false;
    # repluggedPluginCanaryLinks.url = "github:asportnoy/CanaryLinks";
    # repluggedPluginChannelTyping.flake = false;
    # repluggedPluginChannelTyping.url = "github:powercord-community/channel-typing";
    # repluggedPluginClickableEdits.flake = false;
    # repluggedPluginClickableEdits.url = "github:replugged-org/clickable-edits";
    # repluggedPluginCutecord.flake = false;
    # repluggedPluginCutecord.url = "github:powercord-community/cutecord";
    # repluggedPluginEmojiUtility.flake = false;
    # repluggedPluginEmojiUtility.url = "github:replugged-org/emoji-utility";
    # repluggedPluginPersistSettings.flake = false;
    # repluggedPluginPersistSettings.url = "github:venplugs/persistsettings";
    # repluggedPluginThemeToggler.flake = false;
    # repluggedPluginThemeToggler.url = "github:redstonekasi/theme-toggler";
    # repluggedPluginTimestampSender.flake = false;
    # repluggedPluginTimestampSender.url = "github:Anime-Forevere/Timestamp-Sender";
    # repluggedPluginTokiPona.flake = false;
    # repluggedPluginTokiPona.url = "github:somasis/discord-tokipona";
    # repluggedPluginWordFilter.flake = false;
    # repluggedPluginWordFilter.url = "github:A-Trash-Coder/wordfilter";
    # repluggedThemeCustom.flake = false;
    # repluggedThemeCustom.url = "path:/home/somasis/src/discord-theme-custom";
    # repluggedThemeIrc.flake = false;
    # repluggedThemeIrc.url = "github:somasis/discord-theme-irc";

    csl.flake = false;
    csl.url = "github:citation-style-language/styles";
    zoteroTranslators.flake = false;
    zoteroTranslators.url = "github:zotero/translators";

    # hyprland.flake = true;
    # hyprland.url = "github:hyprwm/Hyprland";
    # hyprland.inputs.nixpkgs.follows = "nixpkgs";

    adblockEasyList.flake = false;
    adblockEasyList.url = "github:easylist/easylist";

    adblockEasyListSpanish.flake = false;
    adblockEasyListSpanish.url = "github:easylist/easylistspanish";

    adblockAntiAdblockFilters.flake = false;
    adblockAntiAdblockFilters.url = "github:easylist/antiadblockfilters";

    uAssets.flake = false;
    uAssets.url = "github:uBlockOrigin/uAssets";

    adblockHosts.flake = false;
    adblockHosts.url = "github:StevenBlack/hosts";
  };

  outputs = { self, nixpkgs, home-manager, ... }@inputs:
    let
      inherit (nixpkgs) lib;
      system = builtins.currentSystem or "x86_64-linux";
    in
    {
      overlays.default = final: prev: import ./pkgs { inherit (prev) pkgs; };
      packages = lib.genAttrs lib.systems.flakeExposed (system: import ./pkgs { pkgs = nixpkgs.legacyPackages.${system}; });

      nixosConfigurations.ilo = import ./hosts/ilo.somas.is {
        inherit self inputs nixpkgs;
        overlays = [
          self.overlays.default

          (final: prev: {
            stable = inputs.nixpkgsStable.legacyPackages.${system};
          })
        ];
      };

      homeConfigurations.somasis = home-manager.lib.homeManagerConfiguration {
        pkgs = nixpkgs.legacyPackages.${system};
        modules = [ ./users/somasis ];
      };

      nixosModules = {
        lib = import ./modules/lib.nix;

        impermanence = import ./modules/impermanence.nix;
        home-manager.impermanence = import ./modules/impermanence-hm.nix;
      };
    };
}

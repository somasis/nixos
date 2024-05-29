{
  description = "somas.is";

  inputs = {
    avatarSomasis = {
      # jq -nrR \
      #     --arg hash "$(printf '%s' 'kylie@somas.is' | md5sum | cut -d ' ' -f1)" \
      #     --arg size 512 \
      #     --arg fallback "https://avatars.githubusercontent.com/${USER}?size=512" \
      #     '"url = \"https://www.gravatar.com/avatar/\($hash)?s=\($size)&d=\($fallback | @uri)\";"'
      #     '
      flake = false;
      url = "https://www.gravatar.com/avatar/a187e38560bb56f5231cd19e45ad80f6?s=512";
    };

    flake-compat.url = "github:edolstra/flake-compat";
    flake-compat.flake = false;

    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    nixpkgsStable.url = "github:nixos/nixpkgs?ref=nixos-23.11";

    nixos-hardware.url = "github:nixos/nixos-hardware";

    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    # Use a pre-built nix-index database
    nix-index-database.url = "github:Mic92/nix-index-database";
    nix-index-database.inputs.nixpkgs.follows = "nixpkgs";

    impermanence.url = "github:nix-community/impermanence";

    # catgirl.flake = false;
    # catgirl.url = "git+https://git.causal.agency/catgirl?ref=somasis/tokipona";
    dmenu-flexipatch.flake = false;
    dmenu-flexipatch.url = "github:bakkeby/dmenu-flexipatch";
    lemonbar.flake = false;
    lemonbar.url = "github:drscream/lemonbar-xft/xft-port";
    sbase.flake = false;
    sbase.url = "git://git.suckless.org/sbase";
    ubase.flake = false;
    ubase.url = "github:michaelforney/ubase";

    # vencord.flake = false;
    # vencord.url = "github:Vendicated/Vencord";

    qutebrowser-zotero.flake = false;
    qutebrowser-zotero.url = "github:parchd-1/qutebrowser-zotero";

    zotero-styles.flake = false;
    zotero-styles.url = "github:citation-style-language/styles";
    zotero-translators.flake = false;
    zotero-translators.url = "github:zotero/translators";

    murdos-musicbrainz.flake = false;
    murdos-musicbrainz.url = "github:murdos/musicbrainz-userscripts";

    loujine-musicbrainz.flake = false;
    loujine-musicbrainz.url = "github:loujine/musicbrainz-scripts";

    discordThemeCustom.flake = false;
    discordThemeCustom.url = "path:/home/somasis/src/discord-theme-custom";
    discordThemeIrc.flake = false;
    discordThemeIrc.url = "github:somasis/discord-theme-irc";

    adblockEasyList.flake = false;
    adblockEasyList.url = "github:thedoggybrad/easylist-mirror";

    uAssets.flake = false;
    uAssets.url = "github:uBlockOrigin/uAssetsCDN";

    adblockHosts.flake = false;
    adblockHosts.url = "github:StevenBlack/hosts";

    control-panel-for-twitter.flake = false;
    control-panel-for-twitter.url = "github:insin/control-panel-for-twitter";
  };

  outputs =
    { self
    , nixpkgs
    , home-manager
    , ...
    }@inputs:
    let
      inherit (nixpkgs) lib;
      forAllSystems = lib.genAttrs lib.systems.flakeExposed;
      system = builtins.currentSystem or "x86_64-linux";

      nixpkgsFor = forAllSystems (system: import nixpkgs { inherit system; });
    in
    rec
    {
      overlays.default = final: prev: lib.recursiveUpdate prev (import ./pkgs { pkgs = final; });
      packages = forAllSystems (system: import ./pkgs { pkgs = nixpkgsFor.${system}; });

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

      homeManagerConfigurations = homeConfigurations;

      nixosModules = {
        home-manager = import ./modules/home-manager;

        impermanence = import ./modules/impermanence.nix;
        lib = import ./modules/lib.nix;
        theme = import ./modules/theme.nix;
      };

      homeManagerModules.default = import ./modules/home-manager;

      formatter = forAllSystems (system: nixpkgs.legacyPackages.${system}.nixpkgs-fmt);
    };
}

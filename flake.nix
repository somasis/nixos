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
      url = "https://www.gravatar.com/avatar/a187e38560bb56f5231cd19e45ad80f6?s=512&d=https%3A%2F%2Favatars.githubusercontent.com%2Fsomasis%3Fsize%3D512";
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

    nix-filter.url = "github:numtide/nix-filter";

    # catgirl.flake = false;
    # catgirl.url = "git+https://git.causal.agency/catgirl?ref=somasis/tokipona";
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

    # vencord.flake = false;
    # vencord.url = "github:Vendicated/Vencord";

    qutebrowser-zotero.flake = false;
    qutebrowser-zotero.url = "github:parchd-1/qutebrowser-zotero";

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

  outputs = { self, nixpkgs, home-manager, ... }@inputs:
    let
      inherit (nixpkgs) lib;
      system = builtins.currentSystem or "x86_64-linux";
    in
    {
      overlays.default = import ./pkgs;
      packages = lib.genAttrs lib.systems.flakeExposed
        (
          system:
          import ./pkgs
            nixpkgs.legacyPackages.${system}
            nixpkgs.legacyPackages.${system}
        );

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
        theme = import ./modules/theme.nix;
        home-manager.theme = import ./modules/theme-hm.nix;

        impermanence = import ./modules/impermanence.nix;
        home-manager.impermanence = import ./modules/impermanence-hm.nix;
      };

      formatter =
        lib.genAttrs lib.systems.flakeExposed (system: nixpkgs.legacyPackages.${system}.nixpkgs-fmt);
    };
}

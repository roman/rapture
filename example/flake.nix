{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nix-darwin.url = "github:LnL7/nix-darwin";
    home-manager.url = "github:nix-community/home-manager";
    nix-doom-emacs.url = "github:nix-community/nix-doom-emacs";
    rapture.url = "github:roman/rapture";
  };

  outputs = { nixpkgs, nix-darwin, home-manager, nix-doom-emacs, rapture, ... } @ inputs:
    let
      # this configuration is system agnostic, and can be used both in Linux and
      # Darwin
      homeManagerConfig = { ... }: {
        home.stateVersion = "23.05";
        imports = [
          # enable nix-doom-emacs to manage doomemacs from nix
          nix-doom-emacs.hmModule
          # enable rapture to get this repo's configuration
          rapture.homeManagerModules.rapture
          ({...}: {
            # once inside home-manager, use rapture
            rapture.enable = true;
          })
        ];
      };
    in
    {

      # configure a NixOS system
      nixosConfigurations = {
        myLinux = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          modules = [
            home-manager.nixosModules.home-manager
            ({...}:
              {
                home-manager.users.myUser = homeManagerConfig;
              })
          ];
        };
      };

      # configure a nix-darwin system
      darwinConfigurations = {
        myMac = nix-darwin.lib.darwinSystem {
          system = "aarch64-darwin";
          modules = [
            home-manager.darwinModules.default
            ({...}:
              {
                # configure home-manager *inside* nix-darwin
                home-manager.users.myUser = homeManagerConfig;
              })
          ];
        };
      };

    };
}

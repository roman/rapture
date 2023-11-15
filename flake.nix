{

  nixConfig = {
    extra-substituters = "https://nix-community.cachix.org";
    extra-trusted-public-keys = "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs=";
  };

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-23.05";
    # nixDir.url = "github:roman/nixDir/v2";
    nixDir.url = "git+file:///Users/rgonzalez/Projects/nixDir";
    flake-utils.url = "github:numtide/flake-utils";
    emacs-overlay.url = "github:nix-community/emacs-overlay";
  };

  outputs = { nixpkgs, nixDir, ... } @ inputs:
    nixDir.lib.buildFlake {
      inherit inputs;
      systems = [ "x86_64-linux" "x86_64-darwin" "aarch64-darwin" ];
      root = ./.;

      nixpkgsConfig = {
        # I have to run grammarly-language-server with nodejs16 for it to work
        # without breaking. Unfortunately, nodejs16 is marked as insecure
        # because it is no longer maintained, but for our purpose seems a benign
        # enablement.
        permittedInsecurePackages = [
          "nodejs-16.20.2"
        ];
      };

      packages = pkgs:
        {
          default = pkgs.callPackage (import ./default.nix inputs) {};
        };
    };
}

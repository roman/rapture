{
  nixConfig = {
    extra-trusted-substituters = "https://nix-community.cachix.org";
    extra-trusted-public-keys = "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs=";
  };

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nixDir.url  = "github:roman/nixDir/roman/fix-inputs-for-lib";
    emacs-overlay.url = "github:nix-community/emacs-overlay";
  };

  outputs = { self, nixDir, ... } @ inputs:
    nixDir.lib.buildFlake {
      inherit inputs;
      systems = [ "aarch64-darwin" "x86_64-linux" ];
      root = ./.;
      injectOverlays = [ "develop" ];
      packages = pkgs: {
        emacs = self.lib.mkEmacs pkgs;
      };
      nixpkgsConfig = {
        allowUnfree = true;
      };
    };
}

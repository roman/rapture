{
  nixConfig = {
    extra-trusted-substituters = "https://nix-community.cachix.org";
    extra-trusted-public-keys = "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs=";
  };

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nixDir.url  = "github:roman/nixDir/roman/fix-inputs-for-lib";
    emacs-overlay.url = "github:nix-community/emacs-overlay";

    pyproject = {
      url = "github:pyproject-nix/pyproject.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    uv2nix = {
      url = "github:pyproject-nix/uv2nix";
      inputs.pyproject-nix.follows = "pyproject";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    pyproject-build-systems = {
      url = "github:pyproject-nix/build-system-pkgs";
      inputs.pyproject-nix.follows = "pyproject";
      inputs.uv2nix.follows = "uv2nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
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

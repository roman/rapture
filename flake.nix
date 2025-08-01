{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nixDir.url = "github:roman/nixDir/v3";
    flake-parts.url = "github:hercules-ci/flake-parts";
    nix-flake-tests.url = "github:antifuchs/nix-flake-tests";
    emacs-overlay.url = "github:nix-community/emacs-overlay";
    systems.url = "github:nix-systems/default";
  };

  outputs = inputs:
    inputs.flake-parts.lib.mkFlake { inherit inputs; } {
      imports = [
	inputs.nixDir.flakeModules.default
      ];
      systems = import inputs.systems;
      nixDir = {
	enable = true;
	root = ./.;
      };
      perSystem = {inputs', system, pkgs, ...}: {
	_module.args.pkgs = import inputs.nixpkgs {
	  inherit system;
	  overlays = [
	    (_: _: {
	      inherit (inputs.self.packages.${pkgs.system}) rapture evil;
	    })
	    inputs.emacs-overlay.overlays.default
	  ];
	};
        checks.toposort = inputs.nix-flake-tests.lib.check {
          inherit pkgs;
          tests = import ./nix/lib/toposort_test.nix {
	    inherit (pkgs) lib;
	  };
        };
	checks.rapture = inputs.nix-flake-tests.lib.check {
	  inherit pkgs;
	  tests = import ./nix/lib/rapture_test.nix {
	    inherit (pkgs) lib stdenv writeTextFile replaceVars concatTextFile;
	  };
	};
      };
    };
}

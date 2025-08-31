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
      systems = import inputs.systems;

      imports = [
	inputs.nixDir.flakeModules.default
	inputs.flake-parts.flakeModules.easyOverlay
      ];

      nixDir = {
	enable = true;
	root = ./.;
      };

      perSystem = {inputs', system, pkgs, config, ...}: {
	_module.args.pkgs = import inputs.nixpkgs {
	  inherit system;
	  overlays = [
	    (_: _: {
	      inherit (config.packages) rapture;
	    })
	    inputs.emacs-overlay.overlays.default
	  ];
	};

	overlayAttrs = {
	  inherit (config.packages) rapture;
	};

	checks = {
	  toposort = inputs.nix-flake-tests.lib.check {
	    inherit pkgs;
	    tests = import ./nix/lib/toposort_test.nix {
	      inherit (pkgs) lib;
	    };
	  };
	  rapture = inputs.nix-flake-tests.lib.check {
	    inherit pkgs;
	    tests = import ./nix/lib/rapture_test.nix {
	      inherit (pkgs) lib stdenv writeTextFile replaceVars concatTextFile;
	    };
	  };
	};

      };
    };
}

{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/release-25.11";
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
      ];

      nixDir = {
	enable = true;
	root = ./.;
      };

      flake.overlays.default =
	inputs.nixpkgs.lib.composeExtensions
	  inputs.emacs-overlay.overlays.default
	  (final: prev: {
	    # Use the consumer's package set here. Referencing
	    # inputs.self.packages would instantiate rapture with this flake's
	    # pinned nixpkgs, which can differ from the flake applying the overlay.
	    rapture = final.callPackage ./nix/packages/rapture { };
	  });

      perSystem = {inputs', lib, system, pkgs, config, ...}: {

	_module.args.pkgs = import inputs.nixpkgs {
	  inherit system;
	  overlays = [
	    inputs.self.overlays.default
	  ];
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

	  # The eval tests above show the check phase reaches the derivation.
	  # Only a build shows that stdenv runs it for a plugin that builds
	  # nothing, and that it reads the substituted config rather than the
	  # placeholders.
	  rapture-plugin-check-phase = pkgs.rapture.mkPlugin {
	    name = "plugin-check-phase";
	    src = pkgs.writeText "config.org" "Hello @user@!";
	    vars.user = "nix";
	    checkPhase = ''
	      runHook preCheck
	      grep -Fq 'Hello nix!' "$src"
	      runHook postCheck
	    '';
	  };
	};

      };
    };
}

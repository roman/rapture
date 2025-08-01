{ lib, emptyFile, stdenv, concatTextFile, replaceVars, emacs, emacsWithPackagesFromUsePackage }:

let
  api = import ../../lib/rapture.nix {
    inherit lib stdenv concatTextFile replaceVars;
  };

  buildEmacs = 
    { plugins ? [], package ? emacs }:
      let
	result = api.buildConfig plugins;
      in
	emacsWithPackagesFromUsePackage {
	  inherit package;
	  inherit (result) config;
	  defaultInitFile = true;
	  alwaysEnsure = true;
	  alwaysTangle = true;
	};
in
  # Dummy derivation that does nothing and serves as a bag for functions.
  stdenv.mkDerivation {
    name = "rapture";
    src = emptyFile;
    dontUnpack = true;
    dontConfigure = true;
    dontBuild = true;
    installPhase = ''
      touch $out
    '';
  } // {
    inherit (api) mkPlugin;
    inherit buildEmacs;
  }

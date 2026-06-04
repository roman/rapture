{
  callPackage,
  symlinkJoin,
  lib,
  emptyFile,
  stdenv,
  concatTextFile,
  replaceVars,
  emacs,
  emacsWithPackagesFromUsePackage,
  makeWrapper,
}:

let
  api = import ../../lib/rapture.nix {
    inherit
      lib
      stdenv
      concatTextFile
      replaceVars
      ;
  };

  buildEmacs =
    {
      plugins ? [ ],
      package ? emacs,
      fontPackages ? [ ],
    }:
    let
      result = api.buildConfig plugins;
      runtimeInputs = lib.unique result.runtimeInputs;
      finalFontPackages = lib.unique (fontPackages ++ result.fontPackages);
      runtimePath = lib.makeBinPath runtimeInputs;
      emacs = emacsWithPackagesFromUsePackage {
        inherit package;
        inherit (result) config extraEmacsPackages override;
        defaultInitFile = true;
        alwaysEnsure = true;
        alwaysTangle = true;
      };
    in
    symlinkJoin {
      name = "rapture";
      # runtimeInputs are only added to the wrapped Emacs PATH. Linking them
      # into this output would expose their binaries and can collide with
      # packages installed separately by Home Manager, e.g. git's git-jump.
      paths = [ emacs ] ++ result.buildInputs ++ finalFontPackages;
      passthru = {
        inherit finalFontPackages;
        fontPackages = finalFontPackages;
      };
      nativeBuildInputs = [ makeWrapper ];
      postBuild = lib.optionalString (runtimePath != "") ''
        wrapProgram $out/bin/emacs \
          --prefix PATH : ${lib.escapeShellArg runtimePath} \
          --set RAPTURE_RUNTIME_PATH ${lib.escapeShellArg runtimePath}
      '';
    };

  plugins = {
    evil = callPackage ./plugins/evil { };
    ai = callPackage ./plugins/ai { };
    ui = callPackage ./plugins/ui { };
    basics = callPackage ./plugins/basics { };
    navigation = callPackage ./plugins/navigation { };
    help = callPackage ./plugins/help { };
    coding = callPackage ./plugins/coding { };
    org = callPackage ./plugins/org { };
    langs = callPackage ./plugins/langs { };
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
}
// {
  inherit (api) mkPlugin;
  inherit buildEmacs plugins;
}

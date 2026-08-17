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
      # A launchd agent starts the Emacs daemon with PATH set to
      # /usr/bin:/bin:/usr/sbin:/sbin. macOS contributes the rest of a normal
      # PATH — /usr/local/bin and every /etc/paths.d entry — through
      # path_helper, which /etc/profile runs for login shells only. A daemon is
      # not one, so subprocesses and terminal buffers lose those directories and
      # commands installed outside Nix stop resolving. Running path_helper here
      # gives them the PATH a login shell would have. It puts the system
      # directories first and appends the inherited entries after them, so the
      # runtime prefix below still wins.
      pathHelperArgs = lib.optionals stdenv.hostPlatform.isDarwin [
        "--run"
        ''eval "$(/usr/libexec/path_helper -s)"''
      ];
      runtimePathArgs = lib.optionals (runtimePath != "") [
        "--prefix"
        "PATH"
        ":"
        runtimePath
        "--set"
        "RAPTURE_RUNTIME_PATH"
        runtimePath
      ];
      wrapperArgs = pathHelperArgs ++ runtimePathArgs;
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
      postBuild = lib.optionalString (wrapperArgs != [ ]) ''
        wrapProgram $out/bin/emacs ${lib.escapeShellArgs wrapperArgs}
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

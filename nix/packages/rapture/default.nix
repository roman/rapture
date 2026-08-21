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
      # Prefixes (their /bin appended, as lib.makeBinPath does for every
      # entry) to add to PATH after the plugin runtime inputs. path_helper
      # (below) only ever answers with macOS's own /etc/paths and
      # /etc/paths.d, so it can't restore a caller's own profile directories
      # (e.g. a home-manager profile) — callers that need those pass them
      # here instead. Ordered after runtimeInputs so a plugin's pinned tool
      # is never shadowed by whatever the caller's profile also happens to
      # install (e.g. its own ripgrep or git).
      extraRuntimePrefixes ? [ ],
    }:
    let
      result = api.buildConfig plugins;
      runtimeInputs = lib.unique result.runtimeInputs;
      finalFontPackages = lib.unique (fontPackages ++ result.fontPackages);
      runtimePath = lib.makeBinPath (runtimeInputs ++ extraRuntimePrefixes);
      # A launchd agent starts the Emacs daemon with PATH set to
      # /usr/bin:/bin:/usr/sbin:/sbin. macOS contributes the rest of a normal
      # PATH — /usr/local/bin and every /etc/paths.d entry — through
      # path_helper, which /etc/profile runs for login shells only. Emacs hands
      # its own PATH to every process it starts, so subprocesses and terminal
      # buffers cannot resolve commands installed outside Nix.
      #
      # path_helper answers with the system directories first and the entries it
      # inherited after them. Taking that answer whole would reorder the PATH of
      # an Emacs started from a shell, pushing its front entries — a devenv
      # profile, ~/.nix-profile/bin — behind /usr/bin. So ask twice: once with an
      # empty PATH for the system list on its own, once normally for the list
      # plus whatever was inherited. Removing the first answer from the second
      # leaves the inherited entries, which go back in front. A daemon inherits
      # only system directories, so nothing survives that step and it ends up
      # with the PATH a login shell would have.
      #
      # Both calls sit in subshells because path_helper also rewrites MANPATH,
      # and `M-x man' should keep preferring the Nix profile's pages.
      wrapperArgs =
        lib.optionals stdenv.hostPlatform.isDarwin [
          "--run"
          ''
            rapture_system_path=$(eval "$(PATH= /usr/libexec/path_helper -s)"; printf %s "$PATH")
            rapture_full_path=$(eval "$(/usr/libexec/path_helper -s)"; printf %s "$PATH")
            rapture_inherited_path=''${rapture_full_path#"$rapture_system_path"}
            rapture_inherited_path=''${rapture_inherited_path#:}
            PATH=''${rapture_inherited_path:+$rapture_inherited_path:}$rapture_system_path
          ''
        ]
        ++ lib.optionals (runtimePath != "") [
          "--prefix"
          "PATH"
          ":"
          runtimePath
        ];
      # The Dock, Spotlight and `open -a' start Emacs through the app bundle,
      # which reaches the binary without passing through bin/emacs. A build that
      # carries no bundle — emacs-nox, or any non-darwin one — leaves the second
      # entry point absent, hence the test rather than a platform condition.
      wrapEntryPoints = ''
        for entry_point in \
          "$out/bin/emacs" \
          "$out/Applications/Emacs.app/Contents/MacOS/Emacs"
        do
          if [ -e "$entry_point" ]; then
            wrapProgram "$entry_point" ${lib.escapeShellArgs wrapperArgs}
          fi
        done
      '';
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
      postBuild = lib.optionalString (wrapperArgs != [ ]) wrapEntryPoints;
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

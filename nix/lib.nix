{ self, ... }:

{
  mkEmacs = pkgs:
    let
      # add runtime dependencies to emacs
      inherit (pkgs) emacs;
      configFile = "${self}/config.org";

      emacsNoRTDeps = pkgs.emacsWithPackagesFromUsePackage {
        package = emacs;
        config = configFile;
        defaultInitFile = true;
        alwaysEnsure = true;
        alwaysTangle = true;
      };

      runtimeDeps = builtins.attrValues {
        inherit (pkgs)
          ripgrep gcc gitMinimal
          # nix development
          statix nixpkgs-fmt nil;
      };

      emacsSplash = builtins.fetchurl {
        url = "https://raw.githubusercontent.com/pearcidar/mydotfiles/main/.doom.d/emacs.png";
        sha256 = "sha256:11b3cnfnnyj88jx8hn47bk3yb5dvkmvqqbc4ahwzjlx53wi4c7bm";
      };

    in
    pkgs.symlinkJoin {
      inherit (emacsNoRTDeps) name meta;
      buildInputs = [ pkgs.makeWrapper ];
      paths = [ emacsNoRTDeps ];
      doCheck = true;
      checkPhase = ''
        echo "********************** running check phase"
      '';
      postBuild = ''
        wrapProgram $out/bin/emacs \
        	    --set SPLASH_IMG_PATH ${emacsSplash} \
        	    --prefix PATH : ${pkgs.lib.makeBinPath runtimeDeps}
      '';
    };
}

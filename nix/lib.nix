{ self, ... }:

{
  mkEmacs = pkgs:
    let
      # Add runtime dependencies to emacs.
      inherit (pkgs) emacs;
      inherit (self.packages.${pkgs.system}) mcp-servers revealjs;

      coreConfigFile = pkgs.substituteAll {
        name = "config.org";
        src = "${self}/config.org";
        mcpServerFilesystem = "${mcp-servers}/bin/mcp-server-filesystem";
        mcpServerFetch = "${mcp-servers}/bin/mcp-server-fetch";
        revealjsPath = "${revealjs}";
      };

      configFile = pkgs.concatTextFile {
        name = "config.org";
        files = [ coreConfigFile self.packages.${pkgs.system}.rapture-airbb ];
      };

      emacsNoRTDeps = pkgs.emacsWithPackagesFromUsePackage {
        package = emacs;
        config = configFile;
        defaultInitFile = true;
        alwaysEnsure = true;
        alwaysTangle = true;
        override = final: prev: {
          inherit (self.packages.${pkgs.system}) ginkgo-mode gptel;
          claude-code = self.packages.${pkgs.system}.emacs-claude-code;
          mcp = self.packages.${pkgs.system}.mcpel;
        };
      };

      runtimeDeps = builtins.attrValues {
        inherit (pkgs)
          ripgrep gcc gitMinimal git-absorb plantuml direnv nodejs_22 claude-code;

        inherit (self.packages.${pkgs.system})
          # nix development
          nixlang;
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
      postBuild = ''
        wrapProgram $out/bin/emacs \
        	    --set SPLASH_IMG_PATH ${emacsSplash} \
        	    --prefix PATH : ${pkgs.lib.makeBinPath runtimeDeps}
      '';
    };
}

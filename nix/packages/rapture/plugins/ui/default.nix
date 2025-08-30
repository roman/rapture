{ lib, rapture, symlinkJoin, fira-code, font-awesome, source-code-pro, emacs-all-the-icons-fonts, nerd-fonts, treesitter-context }:

let
  emacs-fonts =
    symlinkJoin {
      name = "emacs-fonts";
      paths = 
	[ fira-code
	  source-code-pro
	  font-awesome
	  emacs-all-the-icons-fonts
	] ++
        builtins.attrValues (lib.filterAttrs (_: p: lib.isDerivation p) nerd-fonts);
    };
    
  splash =
    builtins.fetchurl {
      url = "https://raw.githubusercontent.com/pearcidar/mydotfiles/main/.doom.d/emacs.png";
      sha256 = "sha256:11b3cnfnnyj88jx8hn47bk3yb5dvkmvqqbc4ahwzjlx53wi4c7bm";
    };
in
rapture.mkPlugin {
  name = "ui";
  src = ./config.org;
  buildInputs = [ emacs-fonts ];
  emacsInputs = epkgs: [
    epkgs.posframe
  ];
  override = _self: _super: {
    inherit treesitter-context; 
  };
  depends = ps: [ ps.evil ];
  vars = {
    splash = builtins.toString splash;
  };
}

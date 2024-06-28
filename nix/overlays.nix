{nixpkgs, emacs-overlay, ...} @ inputs:

{
  develop = nixpkgs.lib.composeManyExtensions [
    emacs-overlay.overlays.default 
  ];
}

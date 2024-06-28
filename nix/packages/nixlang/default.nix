_inputs: { symlinkJoin, statix, nixpkgs-fmt, nil }:

symlinkJoin {
  name = "nixlang";
  paths = [ statix nixpkgs-fmt nil ];
}

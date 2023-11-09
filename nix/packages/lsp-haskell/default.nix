inputs: { haskellPackages, emacsPackages }:

let
  hls = haskellPackages.haskell-language-server;
in

emacsPackages.lsp-haskell.overrideAttrs (oldAttrs: {
  patches = (oldAttrs.patches or []) ++
            [ ./default-haskell-language-server.patch ];

  postPatch = ''
  substituteInPlace lsp-haskell.el \
    --replace "@haskell-language-server@" "${hls}/bin/haskell-language-server-wrapper"
  '';
})

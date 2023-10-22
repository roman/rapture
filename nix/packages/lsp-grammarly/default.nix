inputs: { emacsPackages, nodejs_16 }:

emacsPackages.lsp-grammarly.overrideAttrs (oldAttrs: {
  patches = (oldAttrs.patches or []) ++
            [ ./default-lsp-grammarly-server.patch ];

  postPatch = ''
  substituteInPlace lsp-grammarly.el \
    --replace "@grammarly-languageserver@" "${nodejs_16.pkgs.grammarly-languageserver}/bin/grammarly-languageserver"
  '';
})

_inputs: { fetchFromGitHub, emacsPackages, nodejs }:

emacsPackages.trivialBuild {
  pname = "copilot";
  version = "develop";
  src = fetchFromGitHub {
    owner = "copilot-emacs";
    repo = "copilot.el";
    rev = "b5878d6a8c741138b5efbf4fe1c594f3fd69dbdd";
    sha256 = "sha256-02ywlMPku1FIritZjjtxbQW6MmPvSwmRCrudYsUb8bU=";
  };

  # Introduce a patch that adds a placeholder for the node binary setup.
  patches = [ ./node_path.patch ];

  # Embed the nodejs binary to the copilot utility so that we don't rely on global node
  # being installed.
  postPatch = ''
    substituteInPlace copilot.el --replace "__NODEJS_PATH__" "${nodejs}/bin/node"
    substituteInPlace copilot.el --replace "__NPM_PATH__" "${nodejs}/bin/npm"
  '';

  packageRequires = builtins.attrValues {
    inherit (emacsPackages) editorconfig dash f jsonrpc;
  };
}

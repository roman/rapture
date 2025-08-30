{ fetchFromGitHub, emacsPackages }:

emacsPackages.trivialBuild {
  pname = "treesitter-context";
  version = "develop";
  src = fetchFromGitHub {
    owner = "zbelial";
    repo = "treesitter-context.el";
    rev = "master";
    sha256 = "sha256-wH36jBIxItq6gijmZ63xXQFMZNO0ESNR8O1Utfq9TeU=";
  };
  buildInputs = [
    emacsPackages.posframe
  ];
}

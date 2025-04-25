{ self, ... } @ _inputs: { lib, fetchFromGitHub, emacsPackages }:

emacsPackages.trivialBuild {
  pname = "mcp.el";
  version = "devel";
  src = fetchFromGitHub {
    owner = "lizqwerscott";
    repo = "mcp.el";
    rev = "d0f3b5e53c1eded4619e537881e69c4f6d5a2a94";
    sha256 = "sha256-Clsz6WK0pp4hy9KpN2yEsGEBgyR8Yu6s4H1Pk7rTb/I=";
  };
}

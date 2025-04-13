{ self, ... } @ _inputs: { lib, fetchFromGitHub, emacsPackages }:

let
  version = "latest";
in
emacsPackages.trivialBuild {
  pname = "evil";
  inherit version;

  src = fetchFromGitHub {
    owner = "emacs-evil";
    repo = "evil";
    rev = "master";
    sha256 = "sha256-Xu0aP+HkpjltPiHGgxpZBfgDOAKHAegrH+pQ26+Tsp0=";
  };
}

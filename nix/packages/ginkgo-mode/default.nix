{ fetchFromGitHub, emacsPackages }:

emacsPackages.trivialBuild {
  pname = "ginkgo-mode";
  version = "develop";
  src = fetchFromGitHub {
    owner = "garslo";
    repo = "ginkgo-mode";
    rev = "1d2ec32021afdc629ee4faa8fec0aa3826d5b66b";
    sha256 = "sha256-HgqZdh5nzd8lNDzA1kGHKTWOMAM5LBzgAoTPl8kBofo=";
  };
}

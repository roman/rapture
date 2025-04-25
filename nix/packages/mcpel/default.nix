{ self, ... } @ _inputs: { lib, fetchFromGitHub, emacsPackages }:

emacsPackages.trivialBuild {
  pname = "mcp.el";
  version = "devel";
  src = fetchFromGitHub {
    owner = "lizqwerscott";
    repo = "mcp.el";
    rev = "master";
    sha256 = "sha256-Lub72Dlzf5SoI6XPK9CM4kxzeTdJKJHdEZ5MGNMduGQ=";
  };
}

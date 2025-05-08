_inputs: { fetchFromGitHub, emacsPackages }:

emacsPackages.trivialBuild {
  pname = "claude-code";
  version = "develop";
  src = fetchFromGitHub {
    owner = "stevemolitor";
    repo = "claude-code.el";
    rev = "main";
    sha256 = "sha256-EuGFek8Kf/j+sJJZmieQYunV8PJngxcEefsXHXlkes0=";
  };
}

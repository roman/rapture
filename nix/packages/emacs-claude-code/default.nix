{ fetchFromGitHub, emacsPackages }:

emacsPackages.trivialBuild {
  pname = "claude-code";
  version = "develop";
  src = fetchFromGitHub {
    owner = "stevemolitor";
    repo = "claude-code.el";
    rev = "e2f8a8e139c8c31c6b7d22dd475c31f9ef09e4af";
    sha256 = "sha256-DQTcFQhbcOyEwBa34QLgahpW8MXqKbQF1lrmQSW/Azo=";
  };
}

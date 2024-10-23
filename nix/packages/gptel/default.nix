{ self, ... } @ _inputs: { lib, fetchFromGitHub, miller, emacsPackages }:

let
  version = "0.9.6";

  # Download general-purpose prompts and embed them to this project.
  prompts = fetchFromGitHub {
    owner = "f";
    repo = "awesome-chatgpt-prompts";
    rev = "b82b3854cb3c00306e1813af5b3e0bd809596b60";
    sha256 = "sha256-JqW0pPShqzhVFwkQ+xL3HIjdrzHYuosJLoDpihRuNAE=";
  };

in
emacsPackages.trivialBuild {
  pname = "gptel";
  inherit version;

  src = fetchFromGitHub {
    owner = "karthink";
    repo = "gptel";
    rev = "v${version}";
    sha256 = "sha256-qhF9/RnF2C+dhGnoMWOVFCXQzWFrbllZ0A6lwmjnZTE=";
  };

  patches = [ ./prompt.patch ];

  postPatch = ''
    ls -lah
    substituteInPlace gptel.el --replace "__GPTEL_PROMPTS_FILE__" "$out/gptel-prompts.csv"
  '';

  postBuild = ''
    set -x
    mkdir -p $out
    ${miller}/bin/mlr --csv cat ${self}/nix/packages/gptel/prompts.csv ${prompts}/prompts.csv > $out/gptel-prompts.csv;
    cat $out/gptel-prompts.csv
    set +x
  '';
}

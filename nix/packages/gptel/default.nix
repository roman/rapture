{ lib, fetchFromGitHub, emacsPackages }:

let
  version = "0.9.8.5";

  # Download general-purpose prompts and embed them to this project.
  prompts = fetchFromGitHub {
    owner = "f";
    repo = "awesome-chatgpt-prompts";
    rev = "b82b3854cb3c00306e1813af5b3e0bd809596b60";
    sha256 = "sha256-JqW0pPShqzhVFwkQ+xL3HIjdrzHYuosJLoDpihRuNAE=";
  };

  promptsCSV = ./prompts.csv;

in
emacsPackages.trivialBuild {
  pname = "gptel";
  inherit version;

  src = fetchFromGitHub {
    owner = "karthink";
    repo = "gptel";
    rev = "v${version}";
    sha256 = "sha256-5/X4kuN3i7KeqSmdz0aetkiY+udFBxj5iquGtFuaoEc=";
  };

  patches = [ ./prompt.patch ];

  postPatch = ''
    ls -lah
    substituteInPlace gptel.el --replace-fail "__GPTEL_PROMPTS_FILE__" "$out/gptel-prompts.csv"
  '';

  postBuild = ''
    mkdir -p $out
    cat ${promptsCSV} > $out/gptel-prompts.csv
    tail -n +2 ${prompts}/prompts.csv >> $out/gptel-prompts.csv
  '';
}

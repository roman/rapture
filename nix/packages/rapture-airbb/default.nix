_inputs: { replaceVars, }:

replaceVars ./config.org {
  # TODO: investigate how to build iap-auth using nix to avoid global dependencies
  # https://git.musta.ch/airbnb/ergo/tree/master/projects/iap-auth
  iapAuthBin = "/usr/local/bin/iap-auth";
  # TODO: wait for ticket to build package using bazel in nix
  # https://github.com/NixOS/nixpkgs/issues/390395
  airchatCLI = "/Users/roman_gonzalez/Projects/twig/bazel-bin/projects/airchat/cli/airchat_cli/airchat";
}

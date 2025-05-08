_inputs: { replaceVars, }:

# TODO: wait for ticket to build package using bazel in nix to avoid global dependencies
# https://github.com/NixOS/nixpkgs/issues/390395
replaceVars ./config.org {
  # https://git.musta.ch/airbnb/ergo/tree/master/projects/iap-auth
  iapAuthBin = "/usr/local/bin/iap-auth";
  # https://git.musta.ch/airbnb/twig/tree/master/projects/airchat/cli/airchat_cli/airchat
  airchatCLI = "/usr/local/bin/airchat";
}

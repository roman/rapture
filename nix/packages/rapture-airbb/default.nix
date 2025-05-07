_inputs: { substituteAll, }:

substituteAll {
  name = "config.org";
  src = ./config.org;
  # TODO: investigate how to build iap-auth using nix to avoid global dependencies
  # https://git.musta.ch/airbnb/ergo/tree/master/projects/iap-auth
  iapAuthBin = "/usr/local/bin/iap-auth";
}

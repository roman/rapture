{ rapture, }:

rapture.mkPlugin {
  name = "help";
  src = ./config.org;
  depends = ps: [ ps.evil ];
}

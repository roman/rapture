{ rapture, }:

rapture.mkPlugin {
  name = "coding";
  src = ./config.org;
  depends = ps: [ ps.evil ];
}

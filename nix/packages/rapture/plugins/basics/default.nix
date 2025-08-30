{ rapture }:

rapture.mkPlugin {
  name = "basics";
  src = ./config.org;
  depends = ps: [ ps.evil ];
}

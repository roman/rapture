{ rapture, }:

rapture.mkPlugin {
  name = "navigation";
  src = ./config.org;
  depends = ps: [ ps.evil ];
}

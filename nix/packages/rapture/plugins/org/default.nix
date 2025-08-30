{ rapture, plantuml, revealjs }:

rapture.mkPlugin {
  name = "org";
  src = ./config.org;
  depends = ps: [ ps.evil ps.coding ];
  vars = {
    plantuml = "${plantuml}/bin/plantuml";
    revealjsPath = "${revealjs}";
  };
}

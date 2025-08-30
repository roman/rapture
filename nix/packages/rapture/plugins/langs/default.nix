{ rapture, ginkgo-mode }:

rapture.mkPlugin {
  name = "langs";
  src = ./config.org;
  depends = ps: [ ps.evil ps.coding ps.ai ];
  override = _self: _super: {
    inherit ginkgo-mode;
  };
}

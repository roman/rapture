{ rapture, gptel, mcpel, emacs-claude-code, }:

rapture.mkPlugin {
  name = "ai";
  src = ./config.org;
  depends = ps: [ ps.evil ];
  override = _self: _super: {
    inherit gptel;
    claude-code = emacs-claude-code;
    mcp = mcpel;
  };
}

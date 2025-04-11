_inputs: { lib, buildGoModule, fetchFromGitHub }:

let
  version = "0.1.1";
in
buildGoModule {
  name = "github-mcp-server";
  inherit version;

  src = fetchFromGitHub {
    owner = "github";
    repo = "github-mcp-server";
    rev  = "v${version}";
    sha256 = "sha256-cIS6awIzGadeDdIfSmHKlL9NhouZwQAND7Au8zz0HJA=";
  };

  vendorHash = "sha256-eBKTnuJk705oE//ejdwu/hi1hq8N88C6e4dEkKuM+5g=";

  meta = with lib; {
    description = "GitHub's official MCP Server";
    homepage = "https://github.com/github/github-mcp-server";
    license = licenses.mit;
    maintainers = with maintainers; [ roman ];
  };
}

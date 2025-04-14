inputs: { lib, callPackage, callPackages, fetchFromGitHub, buildNpmPackage, nodejs, jq, python311, symlinkJoin, }:

let
  pythonSrc = fetchFromGitHub {
    owner = "modelcontextprotocol";
    repo = "servers";
    tag = "python-servers-0.6.2";
    sha256 = "sha256-UGzt4stV+6N+haBwfGv2i8ruyHjpHnuw4ncECaDdbvE=";
  };

  jsSrc = fetchFromGitHub {
    owner = "modelcontextprotocol";
    repo = "servers";
    tag = "typescript-servers-0.6.2";
    sha256 = "sha256-FKotJUzP29iZzfRqfWGhdZosWxGX7BBOExxznfLi7Us=";
  };

  gitServer = 
    let
      project = inputs.pyproject.lib.project.loadPyproject {
        projectRoot = "${pythonSrc}/src/git";
      };
      appAttrs = project.renderers.buildPythonPackage {
        python = python311;
      };
    in
      python311.pkgs.buildPythonApplication appAttrs;

  fetchServer =
    let
      workspace = inputs.uv2nix.lib.workspace.loadWorkspace {
        workspaceRoot = "${pythonSrc}/src/fetch";
      };
      workspaceOverlay = workspace.mkPyprojectOverlay {
        sourcePreference = "wheel";
      };
      pythonSet = (callPackage inputs.pyproject.build.packages {
        python = python311;
      }).overrideScope (
        lib.composeManyExtensions [
          inputs.pyproject-build-systems.overlays.default
          workspaceOverlay
        ]
      );
      inherit (callPackages inputs.pyproject.build.util { }) mkApplication;
    in
      mkApplication {
        venv = pythonSet.mkVirtualEnv "mcp-server-fetch-venv" workspace.deps.default;
        package = pythonSet.mcp-server-fetch;
      };

  jsServers = buildNpmPackage {
    pname = "mcp-servers";
    version = "0.6.2"; 
    src = "${jsSrc}";

    npmDepsHash = "sha256-fuJQxbHrv/x49I3WDMQxXC/+kuv/JiTDdHiAEaN94Zw="; 

    buildInputs = [ nodejs ];

    PUPPETEER_SKIP_DOWNLOAD=1;

    installPhase = ''
      mkdir $out
      mkdir $out/bin
      cp -R src $out
      cp -R node_modules $out
      ln -s $out/node_modules/@modelcontextprotocol/server-filesystem/dist/index.js $out/bin/mcp-server-filesystem 
      ln -s $out/node_modules/@modelcontextprotocol/server-brave-search/dist/index.js $out/bin/mcp-server-brave-search
      ln -s $out/node_modules/@modelcontextprotocol/server-everart/dist/index.js $out/bin/mcp-server-everart
      ln -s $out/node_modules/@modelcontextprotocol/server-everything/dist/index.js $out/bin/mcp-server-everything
      ln -s $out/node_modules/@modelcontextprotocol/server-gdrive/dist/index.js $out/bin/mcp-server-gdrive
      ln -s $out/node_modules/@modelcontextprotocol/server-github/dist/index.js $out/bin/mcp-server-github
      ln -s $out/node_modules/@modelcontextprotocol/server-gitlab/dist/index.js $out/bin/mcp-server-gitlab
      ln -s $out/node_modules/@modelcontextprotocol/server-google-maps/dist/index.js $out/bin/mcp-server-google-maps
      ln -s $out/node_modules/@modelcontextprotocol/server-memory/dist/index.js $out/bin/mcp-server-memory
      ln -s $out/node_modules/@modelcontextprotocol/server-postgres/dist/index.js $out/bin/mcp-server-postgres
      ln -s $out/node_modules/@modelcontextprotocol/server-puppeteer/dist/index.js $out/bin/mcp-server-puppeteer
      ln -s $out/node_modules/@modelcontextprotocol/server-slack/dist/index.js $out/bin/mcp-server-slack
    '';

    meta = with lib; {
      description = "Model Context Protocol servers";
      homepage = "https://modelcontextprotocol.io";
      license = licenses.mit;
      maintainers = with maintainers; [ roman ];
    };
  };

in
symlinkJoin {
  name = "mcp-servers";
  paths = [
    gitServer
    fetchServer
    jsServers
  ];
}

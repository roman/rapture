{
  lib,
  stdenv,
  concatTextFile,
  replaceVars,
  writeTextFile,
}:

let
  api = import ./rapture.nix {
    inherit
      lib
      stdenv
      concatTextFile
      replaceVars
      ;
  };
  runtimeInput = writeTextFile {
    name = "runtime-input";
    text = "";
  };
  fontPackage = writeTextFile {
    name = "font-package";
    text = "";
  };
  pluginA = api.mkPlugin {
    name = "plugin-a";
    src = writeTextFile {
      name = "config.org";
      text = ''
        plugin A contents
      '';
    };
    depends = plugins: [ plugins.plugin-b ];
  };
  pluginB = api.mkPlugin {
    name = "plugin-b";
    src = writeTextFile {
      name = "config.org";
      text = ''
        plugin B contents
      '';
    };
    runtimeInputs = [ runtimeInput ];
    fontPackages = [ fontPackage ];
  };
  pluginC = api.mkPlugin {
    name = "plugin-c";
    src = writeTextFile {
      name = "config.org";
      text = ''
        plugin C contents
      '';
    };
    depends = plugins: [
      plugins.plugin-b
      plugins.plugin-a
    ];
  };

  plugins = [
    pluginA
    pluginB
    pluginC
  ];

  tests = {
    "test plugins gets sorted in topo order when running configuration" = {
      expr =
        let
          result = api.buildConfig plugins;
        in
        map api.getPluginName result.sortedPlugins;

      expected = [
        "plugin-b"
        "plugin-a"
        "plugin-c"
      ];
    };

    "test config gets contents in topo order" = {
      expr =
        let
          result = api.buildConfig plugins;
        in
        builtins.readFile result.config;

      expected = ''
        plugin B contents
        plugin A contents
        plugin C contents
      '';
    };

    "test config content interpolation" =
      let
        plugin = api.mkPlugin {
          name = "plugin-interpolation";
          src = writeTextFile {
            name = "config.org";
            text = "Hello @user@!";
          };
          vars = {
            user = "nix";
          };
        };
      in
      {
        expr =
          let
            result = api.buildConfig [ plugin ];
          in
          builtins.readFile result.config;

        expected = "Hello nix!";
      };

    "test runtime inputs get collected in plugin order" = {
      expr =
        let
          result = api.buildConfig plugins;
        in
        result.runtimeInputs;

      expected = [ runtimeInput ];
    };

    "test font packages get collected in plugin order" = {
      expr =
        let
          result = api.buildConfig plugins;
        in
        result.fontPackages;

      expected = [ fontPackage ];
    };

  };
in
tests

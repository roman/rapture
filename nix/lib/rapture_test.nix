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

    "test plugin metadata survives overrideAttrs" = {
      expr =
        let
          overridden = pluginB.overrideAttrs (_old: { doCheck = true; });
        in
        {
          rapturePluginInputs = overridden.rapturePluginInputs [ ];
          emacsInputs = overridden.emacsInputs { };
          pluginOverride = overridden.pluginOverride { } { };
          inherit (overridden) runtimeInputs fontPackages;
        };

      expected = {
        rapturePluginInputs = [ ];
        emacsInputs = [ ];
        pluginOverride = { };
        runtimeInputs = [ runtimeInput ];
        fontPackages = [ fontPackage ];
      };
    };

    "test buildConfig reads an overridden plugin" = {
      expr =
        let
          dependent = api.mkPlugin {
            name = "plugin-dependent";
            src = writeTextFile {
              name = "config.org";
              text = ''
                plugin dependent contents
              '';
            };
            depends = ps: [ ps.plugin-b ];
            emacsInputs = epkgs: [ epkgs.marker ];
            override = _self: _super: {
              marker = "overridden";
            };
          };
          overridden = dependent.overrideAttrs (_old: { doCheck = true; });
          result = api.buildConfig [
            overridden
            pluginB
          ];
        in
        {
          names = map api.getPluginName result.sortedPlugins;
          extraEmacsPackages = result.extraEmacsPackages { marker = "marker"; };
          override = result.override { } { };
          inherit (result) runtimeInputs fontPackages;
        };

      expected = {
        names = [
          "plugin-b"
          "plugin-dependent"
        ];
        extraEmacsPackages = [ "marker" ];
        override = {
          marker = "overridden";
        };
        runtimeInputs = [ runtimeInput ];
        fontPackages = [ fontPackage ];
      };
    };

    "test the plugin source carries the substituted vars" = {
      expr =
        let
          plugin = api.mkPlugin {
            name = "plugin-substituted-src";
            src = writeTextFile {
              name = "config.org";
              text = "Hello @user@!";
            };
            vars = {
              user = "nix";
            };
          };
        in
        builtins.readFile plugin.src;

      expected = "Hello nix!";
    };

    "test plugin without a check phase does not check" = {
      expr = pluginB.doCheck;
      expected = false;
    };

    # The `rapture-plugin-check-phase' flake check builds a plugin whose check
    # phase must fail on an unsubstituted config. It would pass without ever
    # running if `doCheck' were unset, which is what this pins.
    "test plugin check phase reaches the derivation" = {
      expr =
        let
          plugin = api.mkPlugin {
            name = "plugin-checked";
            src = writeTextFile {
              name = "config.org";
              text = "plugin contents";
            };
            checkPhase = "true";
            nativeCheckInputs = [ runtimeInput ];
          };
        in
        {
          inherit (plugin) doCheck checkPhase;
          # stdenv folds nativeCheckInputs into nativeBuildInputs when it
          # checks, so this is where a check tool becomes observable.
          checkInputReachesBuild = builtins.elem runtimeInput plugin.nativeBuildInputs;
        };

      expected = {
        doCheck = true;
        checkPhase = "true";
        checkInputReachesBuild = true;
      };
    };

  };
in
tests

{ lib, stdenv, concatTextFile, replaceVars, ... }:

let
  assertPluginType = plugin:
    if (lib.typeOf plugin != "set") || !(plugin ? rapturePluginInputs) then
      throw "using invalid type for rapture plugin"
    else 
      plugin;

  parsePlugins =
    builtins.concatMap
      (p: if p ? rapturePluginInputs then
            [p]
	  else
             builtins.warn "Skipping plugin ${p.name}. It must be built using rapture.mkPlugin" []);

  getPluginName = plugin:
    (assertPluginType plugin).name;

  getPluginDependencies = plugin:
    map getPluginName plugin.rapturePluginInputs or [];

  getPluginsFromScope = pluginsScope:
    lib.removeAttrs pluginsScope ["callPackage" "newScope" "overrideScope" "packages"];

  concatPluginContents = plugins:
    concatTextFile {
      name = "config.org";
      files = map toString plugins;
    };

  # concatPluginEmacsInputs combines the emacsInputs setting for each plugin.
  concatPluginEmacsInputs = plugins: epkgs:    
    builtins.concatLists (map (plugin: plugin.emacsInputs epkgs) plugins);

  # concatPluginOverride combines the overrides of each plugin.
  concatPluginOverride = plugins: self: super:
    builtins.foldl'
      lib.mergeAttrs
      {}
      (map (plugin: plugin.pluginOverride self super) plugins);

  concatPluginBuildInputs = plugins:
    builtins.concatLists (map (plugin: plugin.buildInputs) plugins);

  concatPluginRuntimeInputs = plugins:
    builtins.concatLists (map (plugin: plugin.runtimeInputs) plugins);

  mkPlugin =
    { name,
      version     ? "develop",
      depends     ? (_plugins: []),
      buildInputs ? [],
      # Executables Emacs subprocesses need after startup. These are added to
      # the final Emacs wrapper PATH, unlike buildInputs-only resources.
      runtimeInputs ? [],
      emacsInputs ? (_epkgs: []),
      override    ? (_self: _super: {}),
      vars ? {},
      src,
    }:
      let
	resolvedSrc =
	  if vars == {} 
	  then src 
	  else replaceVars src vars;
	# Rename depends so that we have a more domain specific key in the derivation.
	rapturePluginInputs = depends;
      in
        stdenv.mkDerivation {
	  # Standard mkDerivation arguments
          inherit name version buildInputs;
	  dontUnpack = true;
	  dontBuild = true;
	  dontConfigure = true;
          installPhase = ''
            if [ -f "${resolvedSrc}" ]; then
              cp ${resolvedSrc} $out
            else
              echo "Error: Source file not found: ${resolvedSrc}"
              exit 1
            fi
	  '';
        } //
	# Keys that rapturePlugin derivations will have, these will later be used by the
	# buildEmacs function to do the topological sorting.
        {
	  inherit emacsInputs rapturePluginInputs runtimeInputs;
	  pluginOverride = override;
	};

  topoSort =
    import ./toposort.nix { inherit lib; } getPluginName getPluginDependencies;

  # buildConfig creates the final config.org file with the given rapture plugins.
  buildConfig = plugins:
    let
	parsedPlugins = parsePlugins plugins;

	# Dark magic, build the plugins entry in the depends attribute
	# for mkPlugin calls.
	pluginScope = lib.makeScope lib.callPackageWith (self:
	  builtins.listToAttrs
	    (map
	      (plugin: {
		name = getPluginName plugin;
		value = plugin // {
		  rapturePluginInputs =
		    if builtins.isFunction plugin.rapturePluginInputs then
                      plugin.rapturePluginInputs self 
		    else
		      plugin.rapturePluginInputs;
		};
	      })
	      parsedPlugins));

	resolvedPlugins = lib.attrValues (getPluginsFromScope pluginScope);

	sortedPlugins = topoSort resolvedPlugins;

	config = concatPluginContents sortedPlugins;
        extraEmacsPackages = concatPluginEmacsInputs sortedPlugins;
        buildInputs = concatPluginBuildInputs sortedPlugins;
        runtimeInputs = concatPluginRuntimeInputs sortedPlugins;
        override = concatPluginOverride sortedPlugins;
    in
      {
	inherit pluginScope parsedPlugins resolvedPlugins sortedPlugins
                config extraEmacsPackages buildInputs runtimeInputs override;
      };
in
  {
    inherit getPluginName getPluginDependencies parsePlugins buildConfig mkPlugin ;concatSortedPluginContents = concatPluginContents; 
  }

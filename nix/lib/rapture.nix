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

  concatSortedPluginContents = plugins:
    concatTextFile {
      name = "config.org";
      files = map toString plugins;
    };

  mkPlugin =
    { name, version ? "develop", depends ? [], buildInputs ? [], emacsInputs ? [], src, vars ? {} }:
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
        { inherit emacsInputs rapturePluginInputs; };

  topoSort =
    import ./toposort.nix { inherit lib; } getPluginName getPluginDependencies;

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

	config = concatSortedPluginContents sortedPlugins;
    in
      {
	inherit pluginScope parsedPlugins resolvedPlugins sortedPlugins config;
      };
in
  {
    inherit getPluginName getPluginDependencies parsePlugins buildConfig mkPlugin concatSortedPluginContents; 
  }

{ lib }:

let
  topoSort = getKey: getSiblings: nodes:
    let
      # Create a lookup map from node key to node
      nodeMap = builtins.listToAttrs (
        map (node: { 
          name = getKey node; 
          value = node; 
        }) nodes
      );
      
      # DFS-based topological sort with cycle detection
      visit = visited: visiting: node:
        let
          nodeKey = getKey node;
	  deps = getSiblings node;
        in
          if builtins.elem nodeKey visiting then
            throw "Circular dependency detected involving plugin: ${nodeKey}"
          else if builtins.elem nodeKey visited then
            # Already processed, return empty result
            { inherit visited; result = []; }
          else
            let
              newVisiting = visiting ++ [nodeKey];
              
              # Visit all dependencies first
              visitDependency = acc: depName:
                if nodeMap ? ${depName} then
                  let
                    depResult = visit acc.visited newVisiting nodeMap.${depName};
                  in {
                    visited = depResult.visited;
                    result = acc.result ++ depResult.result;
                  }
                else
                  throw "Dependency '${depName}' not found. Required by '${nodeKey}'";
              
              depResults = builtins.foldl' visitDependency 
                { visited = visited; result = []; } 
                deps;
            in {
              visited = depResults.visited ++ [nodeKey];
              result = depResults.result ++ [node];
            };
      
      # Visit all plugins, avoiding duplicates in final result
      processAllNodes = nodes:
        let
          processNode = acc: node:
            let
              result = visit acc.visited [] node;
              # Filter out nodes already in the result to avoid duplicates
              newNodes = builtins.filter 
                (n: !(builtins.any (existing: getKey existing == getKey n) acc.result))
                result.result;
            in {
              visited = result.visited;
              result = acc.result ++ newNodes;
            };
        in
          (builtins.foldl' processNode { visited = []; result = []; } nodes).result;
    in
      processAllNodes nodes;
in
  topoSort

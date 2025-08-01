{ lib }:

let
  topoSort = import ./toposort.nix { inherit lib; } (a: a.name) (a: a.deps or []);
  mkNode = name: deps: { inherit name; deps = deps; };
  
  tests = {
    "test linear chain dependency" = {
      expr = map (p: p.name) (topoSort [
        (mkNode "A" ["B"])
        (mkNode "B" ["C"])
        (mkNode "C" [])
      ]);
      expected = ["C" "B" "A"];
    };

    "test diamond dependency" = {
      expr = map (p: p.name) (topoSort [
	(mkNode "A" ["B" "C"])
        (mkNode "B" ["D"])
        (mkNode "C" ["D"])
        (mkNode "D" [])
      ]);
      # Note: B and C order may vary, both valid.
      expected = ["D" "B" "C" "A"];
    };

    "test independent nodes" = {
      expr = map (p: p.name) (topoSort [
	(mkNode "A" [])
        (mkNode "B" [])
        (mkNode "C" [])
      ]);
      # Any order is valid.
      expected = ["A" "B" "C"];

    };
    
    "test empty input" = {
      expr = topoSort [];
      expected = [];
    };

    "test single node" = {
      expr = map (p: p.name) (topoSort [(mkNode "A" [])]);
      expected = ["A"];
    };
    
    "test circular dependency" = {
      expr = builtins.tryEval (topoSort [
        (mkNode "A" ["B"])
        (mkNode "B" ["A"])
      ]);
      expected = { success = false; value = false; };
    };

    "test missing node" = {
      expr = builtins.tryEval (topoSort [
        (mkNode "A" ["NonExisting"])
      ]);
      expected = { success = false; value = false; };
    };

  };

in
tests

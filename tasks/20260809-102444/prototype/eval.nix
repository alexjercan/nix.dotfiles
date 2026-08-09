let
  lib = import <nixpkgs/lib>;
  module = import ./module-interface.nix {
    inherit lib;
    builtInSkills.plan = ./fixtures/plan;
  };
  evaluate = extraSkills:
    (lib.evalModules {
      modules = [
        module
        {
          programs.agents = {
            enable = true;
            inherit extraSkills;
          };
        }
      ];
    }).config.programs.agents.finalSkills;
  merged = evaluate {tatr = ./fixtures/tatr;};
  collision = builtins.tryEval (builtins.deepSeq
    (evaluate {plan = ./fixtures/tatr;})
    true);
in
assert builtins.attrNames merged == ["plan" "tatr"];
assert !collision.success;
{
  names = builtins.attrNames merged;
  sources = builtins.mapAttrs (_name: source: builtins.toString source) merged;
  collisionRejected = !collision.success;
}

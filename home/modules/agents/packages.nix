{
  pkgs,
  sourceRoot ? ./.,
}: let
  codexSkills = pkgs.writeShellApplication {
    name = "agents-deploy-codex-skills";
    runtimeInputs = [pkgs.coreutils];
    text = builtins.readFile (sourceRoot + "/scripts/deploy-codex-skills.sh");
  };
in {
  deploy-codex-skills = codexSkills;
  plannotator = pkgs.callPackage (sourceRoot + "/plannotator.nix") {};
}

{
  pkgs,
  sourceRoot ? ./.,
}: let
  codexSkills = pkgs.writeShellApplication {
    name = "agents-deploy-codex-skills";
    runtimeInputs = [pkgs.coreutils];
    text = builtins.readFile (sourceRoot + "/scripts/deploy-codex-skills.sh");
  };

  knowledge = pkgs.writeTextFile {
    name = "knowledge";
    destination = "/bin/knowledge";
    executable = true;
    text =
      builtins.replaceStrings
      ["#!/usr/bin/env python3"]
      ["#!${pkgs.python3}/bin/python3"]
      (builtins.readFile (sourceRoot + "/scripts/knowledge.py"));
  };
in {
  inherit knowledge;
  deploy-codex-skills = codexSkills;
  plannotator = pkgs.callPackage (sourceRoot + "/plannotator.nix") {};
}

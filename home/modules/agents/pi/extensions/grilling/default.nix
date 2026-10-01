{pkgs}: {
  extension = pkgs.runCommand "agents-nix-pi-extension-grilling" {} ''
    mkdir -p "$out"
    cp ${./package.json} "$out/package.json"
    cp ${./grilling.ts} "$out/grilling.ts"
  '';
}

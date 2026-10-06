{pkgs}: {
  extension = pkgs.runCommand "agents-nix-pi-extension-nvim-bridge" {} ''
    mkdir -p "$out"
    cp ${./package.json} "$out/package.json"
    cp ${./bridge.ts} "$out/bridge.ts"
  '';
}

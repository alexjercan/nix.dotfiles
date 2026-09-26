{pkgs}: {
  # Pi supplies the peer dependencies at runtime. The development dependencies
  # in package.json are only for the local tests and type check.
  extension = pkgs.runCommand "agents-nix-pi-extension-tasks" {} ''
    mkdir -p "$out"
    cp ${./package.json} "$out/package.json"
    cp ${./tasks.ts} "$out/tasks.ts"
  '';
}

{pkgs}: let
  version = "0.1.6";
  source = pkgs.fetchFromGitHub {
    owner = "alexjercan";
    repo = "pi-subagents";
    rev = "v${version}";
    hash = "sha256-snuTCAhxJw4YKwxDv6SbbeJ79/0HDR9y3CMhtHbX2io=";
  };
  manifest = pkgs.lib.importJSON (source + "/package.json");
  lock = pkgs.lib.importJSON (source + "/package-lock.json");
  runtimeManifest = builtins.removeAttrs manifest ["devDependencies"];
  runtimePackages = pkgs.lib.filterAttrs (name: package:
    name == "" || !(package.dev or false))
  lock.packages;
  runtimeLock =
    lock
    // {
      packages =
        runtimePackages
        // {
          "" = builtins.removeAttrs runtimePackages."" ["devDependencies"];
        };
    };
  runtimeNpmRoot = pkgs.runCommand "pi-subagents-npm-root" {} ''
    mkdir -p "$out"
    cp ${pkgs.writeText "package.json" (builtins.toJSON runtimeManifest)} \
      "$out/package.json"
    cp ${pkgs.writeText "package-lock.json" (builtins.toJSON runtimeLock)} \
      "$out/package-lock.json"
  '';
  nodeModules = pkgs.importNpmLock.buildNodeModules {
    npmRoot = runtimeNpmRoot;
    nodejs = pkgs.nodejs_24;

    derivationArgs = {
      pname = "pi-subagents-node-modules";
      inherit version;
      npmFlags = ["--legacy-peer-deps" "--omit=dev"];
    };
  };
  extension =
    pkgs.runCommand "pi-subagents-${version}" {
      passthru = {inherit nodeModules version;};
    } ''
      mkdir -p "$out"
      cp -R ${source}/extensions "$out/extensions"
      cp -R ${source}/examples "$out/examples"
      cp ${source}/package.json "$out/package.json"
      cp ${source}/README.md "$out/README.md"
      ln -s ${nodeModules}/node_modules "$out/node_modules"
    '';
in {
  inherit extension;
}

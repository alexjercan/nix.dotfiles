{
  pkgs,
  npmRoot,
  packageName,
  nodejs ? pkgs.nodejs,
  # Skill roots inside the npm package, relative to its own root. Pi resolves
  # the `pi.extensions` entry below through the dependency's own manifest but
  # does not inherit its other resource kinds, so a package that also ships
  # skills has to name them here to get them loaded.
  skills ? [],
}: let
  lib = pkgs.lib;
  packageJsonPath = npmRoot + "/package.json";
  packageLockPath = npmRoot + "/package-lock.json";
  packageJson = lib.importJSON packageJsonPath;
  packageLock = lib.importJSON packageLockPath;
  environmentName = packageJson.name or null;
  declaredVersion = (packageJson.dependencies or {}).${packageName} or null;
  lockKey = "node_modules/${packageName}";
  lockedPackage = (packageLock.packages or {}).${lockKey} or null;
  lockedVersion =
    if lockedPackage == null
    then null
    else lockedPackage.version or null;

  nodeModules = pkgs.importNpmLock.buildNodeModules {
    inherit npmRoot nodejs;

    derivationArgs = {
      pname = "${environmentName}-node-modules";
      version = lockedVersion;
      # Pi supplies extension peer dependencies at runtime.
      npmFlags = ["--legacy-peer-deps"];
    };
  };

  manifest = pkgs.writeText "${environmentName}-package.json" (builtins.toJSON {
    name = environmentName;
    private = true;
    pi =
      {
        extensions = ["./node_modules/${packageName}"];
      }
      // lib.optionalAttrs (skills != []) {
        skills = map (path: "./node_modules/${packageName}/${path}") skills;
      };
  });

  extension =
    pkgs.runCommand "${environmentName}-${lockedVersion}" {
      passthru = {
        inherit packageName nodeModules;
        version = lockedVersion;
      };
    } ''
      mkdir -p "$out"
      ln -s ${manifest} "$out/package.json"
      ln -s ${nodeModules}/node_modules "$out/node_modules"
    '';
in
  assert lib.assertMsg (builtins.pathExists packageJsonPath)
  "Missing ${toString packageJsonPath}";
  assert lib.assertMsg (builtins.pathExists packageLockPath)
  "Missing ${toString packageLockPath}";
  assert lib.assertMsg (environmentName != null)
  "${toString packageJsonPath} must define name";
  assert lib.assertMsg (declaredVersion != null)
  "${packageName} must be a direct dependency in ${toString packageJsonPath}";
  assert lib.assertMsg (lockedPackage != null)
  "${packageName} is missing from ${toString packageLockPath}";
  assert lib.assertMsg (lockedVersion != null)
  "${packageName} has no locked version in ${toString packageLockPath}";
  assert lib.assertMsg (declaredVersion == lockedVersion)
  "${packageName} must use exact version ${lockedVersion}, not ${declaredVersion}"; extension

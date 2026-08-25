{
  lib,
  stdenv,
  fetchurl,
  autoPatchelfHook,
  makeWrapper,
  git,
  xdg-utils,
  # Pinned by the npm lock of this directory: the CLI and the Pi extension ship
  # from one upstream release. Bump the lock, then update `hash` below.
  version,
}:
stdenv.mkDerivation (finalAttrs: {
  pname = "plannotator";
  inherit version;

  src = fetchurl {
    url = "https://github.com/backnotprop/plannotator/releases/download/v${finalAttrs.version}/plannotator-linux-x64";
    hash = "sha256-6tHSdH1uWFYRm8lCpufmyFH2czh6P1Z+cyKm2TseHLA=";
  };

  dontUnpack = true;
  # Stripping removes Bun's embedded application trailer and leaves only the runtime.
  dontStrip = true;

  nativeBuildInputs = [
    autoPatchelfHook
    makeWrapper
  ];

  buildInputs = [stdenv.cc.cc.lib];

  installPhase = ''
    runHook preInstall

    install -Dm755 "$src" "$out/bin/plannotator"
    wrapProgram "$out/bin/plannotator" \
      --prefix PATH : ${lib.makeBinPath [git xdg-utils]}

    runHook postInstall
  '';

  meta = {
    description = "Interactive plan review for AI coding agents";
    homepage = "https://plannotator.ai";
    license = [lib.licenses.mit lib.licenses.asl20];
    mainProgram = "plannotator";
    platforms = ["x86_64-linux"];
  };
})

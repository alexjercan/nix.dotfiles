{
  lib,
  stdenv,
  fetchurl,
  autoPatchelfHook,
  makeWrapper,
  git,
  xdg-utils,
}:
stdenv.mkDerivation (finalAttrs: {
  pname = "plannotator";
  version = "0.27.3";

  src = fetchurl {
    url = "https://github.com/backnotprop/plannotator/releases/download/v${finalAttrs.version}/plannotator-linux-x64";
    hash = "sha256-YpXiRnfgMqvsEIzGsCh12y+G0oLf3l181yW1uS6/9ow=";
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

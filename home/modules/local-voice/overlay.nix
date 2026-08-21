_final: prev: {
  piper-tts = prev.piper-tts.overrideAttrs (old: {
    patches = (old.patches or []) ++ [./piper-stdout.patch];
  });
}

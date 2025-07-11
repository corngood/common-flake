{ stdenv }: stdenv.mkDerivation {
  name = "git-p4-utils";

  dontUnpack = true;

  installPhase = ''
    runHook preInstall
    mkdir -p $out/bin
    cp ${./bin}/* $out/bin
    runHook postInstall
  '';
}

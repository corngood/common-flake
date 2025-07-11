{ lib, stdenv
, fetchFromGitHub
, fetchurl
, mono6
, msbuild
, dotnet-sdk
, makeWrapper
, dotnetPackages
, unzip
, writeText
}:

let

  deps = map (package: stdenv.mkDerivation (with package; {
    pname = name;
    inherit version src;

    buildInputs = [ unzip ];
    unpackPhase = ''
      unzip $src
      chmod -R u+r .
      function traverseRename () {
        for e in *
        do
          t="$(echo "$e" | sed -e "s/%20/\ /g" -e "s/%2B/+/g")"
          [ "$t" != "$e" ] && mv -vn "$e" "$t"
          if [ -d "$t" ]
          then
            cd "$t"
            traverseRename
            cd ..
          fi
        done
      }

      traverseRename
    '';

    installPhase = ''
      runHook preInstall

      package=$out/lib/dotnet/${name}/${version}
      mkdir -p $package
      cp -r . $package
      echo "{}" > $package/.nupkg.metadata

      runHook postInstall
    '';
  }))
    (import ./deps.nix { inherit fetchurl; });

  nuget-config = writeText "NuGet.Config" ''
    <?xml version="1.0" encoding="utf-8"?>
    <configuration>
      <packageSources>
        <clear />
      </packageSources>
      <fallbackPackageFolders>
        ${lib.concatStringsSep "\n" (map (package: "<add key=\"${package}\" value=\"${package}/lib/dotnet\"/>") deps)}
      </fallbackPackageFolders>
    </configuration>
  '';

in stdenv.mkDerivation rec {

  pname = "unity-debug";
  version = "3.0.2";

  src = fetchFromGitHub {
    owner = "corngood";
    repo = "vscode-unity-debug";
    rev = "1d4bc2e0bee91de6d9a239126797c7c5ccc4a900";
    sha256 = "sha256-yKra9K8D9/TsNiQBfEbDpeuLELdot6icmeiUFdAJCTI=";
    fetchSubmodules = true;
  };

  nativeBuildInputs = [ makeWrapper msbuild ];

  postPatch = ''
    pushd nrefactory/ICSharpCode.NRefactory.CSharp/Parser/mcs
    iconv -fiso8859-1 -tutf8 visit.cs > visit.cs~
    mv visit.cs~ visit.cs
    popd
  '';

  buildPhase = ''
    runHook preBuild

    HOME=$(pwd)/fake-home msbuild -r -p:Configuration=Release -p:RestoreConfigFile=${nuget-config} UnityDebug/UnityDebug.csproj

    runHook postBuild
  '';

  installPhase = ''
    mkdir -p $out/bin $out/lib/mono/UnityDebug/
    cp -r bin/* $out/lib/mono/UnityDebug/
    makeWrapper ${mono6}/bin/mono $out/bin/UnityDebug \
      --add-flags "$out/lib/mono/UnityDebug/UnityDebug.exe"
  '';

  meta = with lib; {
    description = "DAP compatible debugger for Unity";
    homepage = "https://github.com/Unity-Technologies/vscode-unity-debug";
    platforms = platforms.linux;
    license = licenses.mit;
    maintainers = with maintainers; [ corngood ];
  };

}

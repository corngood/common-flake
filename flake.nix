{
  inputs = {
  };

  outputs =
    {
      self,
      nixpkgs,
    }:
    let
      lib = nixpkgs.lib;
      forAllSystems = lib.genAttrs lib.systems.flakeExposed;
    in
    {
      packages = forAllSystems (
        system:
        let
          prev = nixpkgs.legacyPackages.${system};
          pkgs = import prev.path {
            inherit (prev) overlays system;
            config = prev.config // {
              permittedInsecurePackages = map (x: x.name) (
                with pkgs;
                [
                  dotnet-sdk_6.unwrapped
                  dotnet-runtime_6.unwrapped
                ]
              );
            };
          };
        in
        {
          unity-debug = pkgs.callPackage ./unity-debug { };
          git-p4-utils = pkgs.callPackage ./git-p4-utils { };
        }
      );

      devShell = forAllSystems (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
        in
        pkgs.mkShell {
          nativeBuildInputs = [ pkgs.nixfmt-rfc-style ];
        }
      );
    };
}

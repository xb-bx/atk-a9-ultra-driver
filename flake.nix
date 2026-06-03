{
  description = "Linux driver for ATK A9 ultra mouse";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, utils }:
    utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };
      in
      {
        packages.default = pkgs.stdenv.mkDerivation {
          pname = "atk-a9-ultra-driver";
          version = "1.0.0";

          src = ./.;

          buildInputs = with pkgs; [ libusb1 ];

          nativeBuildInputs = with pkgs; [
            odin
          ];

          dontConfigure = true;

          buildPhase = ''
            runHook preBuild
	    odin build . -o:speed -out:atk-a9-ultra-driver 
            runHook postBuild
          '';

          installPhase = ''
            runHook preInstall
            
            mkdir -p $out/bin
            cp atk-a9-ultra-driver $out/bin/
	    mkdir -p $out/etc/udev/rules.d
	    cp ./99-atk-a9-ultra.rules   $out/etc/udev/rules.d
            runHook postInstall
          '';
        };

        devShells.default = pkgs.mkShell {
          buildInputs = with pkgs; [
            odin
            ols 
          ];
        };
      }
    );
}

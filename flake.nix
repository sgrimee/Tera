{
  description = "Rust dev environment using oxalica";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    fenix = {
      url = "github:nix-community/fenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    flake-utils = {
      url = "github:numtide/flake-utils";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = {
    self,
    nixpkgs,
    fenix,
    flake-utils,
    ...
  }:
    flake-utils.lib.eachDefaultSystem (
      system: let
        pkgs = import nixpkgs {
          inherit system;
          overlays = [
            fenix.overlays.default
          ];
          config.allowUnfree = true;
          config.cudaSupport = true;
        };

        toolchain = with fenix.packages.${system}; fromToolchainFile {
          file = ./rust-toolchain.toml; # alternatively, dir = ./.;
          sha256 = "sha256-e4mlaJehWBymYxJGgnbuCObVlqMlQSilZ8FljG9zPHY=";
        };

      in {
        devShell = pkgs.mkShell.override { stdenv = pkgs.gcc12Stdenv; } {

          # build environment
          nativeBuildInputs = with pkgs; [
            # clang
            openssl.dev
            pkg-config
            toolchain
          ]
          ++ lib.optionals pkgs.stdenv.isLinux
            [
              cudaPackages.cudatoolkit
              cudaPackages.cudnn
              linuxPackages.nvidia_x11
            ];

          # runtime environment
          buildInputs = with pkgs;
            [
              toolchain
              bacon
              clippy
              # git-cliff
              rust-analyzer-nightly

              # python311
              # python311Packages.pip
              # python311Packages.virtualenv
            ]
            ++ lib.optionals pkgs.stdenv.isDarwin [
              pkgs.libiconv
              pkgs.darwin.apple_sdk.frameworks.Metal
              pkgs.darwin.apple_sdk.frameworks.MetalPerformanceShaders
              pkgs.darwin.apple_sdk.frameworks.Security
              pkgs.darwin.apple_sdk.frameworks.CoreServices
              pkgs.darwin.apple_sdk.frameworks.SystemConfiguration
            ];
          
          shellHook = ''
              export LD_LIBRARY_PATH="${pkgs.linuxPackages.nvidia_x11}/lib"
          '';

          CUDA_ROOT = "${pkgs.cudatoolkit}";
        };

        defaultPackage = pkgs.mkRustPackage {
          cargoSha256 = "46652094fc5f1f00761992c876b6712052edd15eefd93b2e309833a30af94a95";
          src = ./.;
        };
      }
    );
}

{
  description = "osxcross dev env with overridden LLVM and proper cctools/ld64 integration";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs = { self, nixpkgs }: let
    system = "x86_64-linux";

    overlays = [(final: prev: let
      llvmSrc = prev.fetchFromGitHub {
        owner = "swiftlang";
        repo = "llvm-project";
        rev = "stable/20250402";
        hash = "sha256-/zWc7rQvbiqaJ4K2keuoDIQpu5oiZzOp5bWH3SgF7TI=";
      };

      llvmPackagesSet = prev.recurseIntoAttrs (
        prev.callPackage "${prev.path}/pkgs/development/compilers/llvm" {
          version = "20.1.5-osxcross";
          src_llvm = llvmSrc;
          src_clang = llvmSrc;
          src_lld = llvmSrc;
          src_lldb = llvmSrc;
          src_bolt = null;
          src_openmp = null;

          extraCMakeFlags = [
            "-DCLANG_RESOURCE_DIR=lib/clang/20.1.5"
          ];

          extraPatches = {
            llvm = [ ./unbreak-apple-lld.patch ];
            lld  = [ ./unbreak-apple-lld.patch ];
          };
        }
      );

      macosxSDK = prev.callPackage ./sdk.nix {};

      libtapi = prev.callPackage ./pkgs/apple-libtapi {
        llvm = llvmPackagesSet."20".llvm;
      };

      cctools = prev.callPackage ./pkgs/cctools-port {
        inherit libtapi;
      };

      wrappedClang = prev.writeShellScriptBin "o64-clang" ''
        exec ${llvmPackagesSet."20".clang}/bin/clang \
          --target=x86_64-apple-darwin20.4 \
          -isysroot ${macosxSDK} \
          -mmacosx-version-min=11.0 \
          -fuse-ld=ld64 \
          -B${cctools}/bin \
          "$@"
      '';

      wrappedClangPP = prev.writeShellScriptBin "o64-clang++" ''
        exec ${llvmPackagesSet."20".clang}/bin/clang++ \
          --target=x86_64-apple-darwin20.4 \
          -isysroot ${macosxSDK} \
          -mmacosx-version-min=11.0 \
          -fuse-ld=ld64 \
          -B${cctools}/bin \
          "$@"
      '';

    in {
      llvmPackages_20 = llvmPackagesSet."20";
      clang_20 = llvmPackagesSet."20".clang;
      lld_20 = llvmPackagesSet."20".lld;
      llvm_20 = llvmPackagesSet."20".llvm;
      inherit macosxSDK libtapi cctools wrappedClang wrappedClangPP;
    })];  

    pkgs = import nixpkgs { inherit system overlays; };
  in {
    packages.${system} = {
      inherit (pkgs) llvmPackages_20 clang_20 lld_20 llvm_20 wrappedClang wrappedClangPP macosxSDK;
    };

    devShell.${system} = pkgs.mkShell {
      name = "osxcross-dev";

      buildInputs = with pkgs; [
        automake autoconf cmake ninja
        curl wget git patch python3
        openssl libxml2 bzip2 xz unzip zlib zlib-ng pkg-config
        clang_20 lld_20 cctools wrappedClang wrappedClangPP
      ];

      shellHook = ''
        export CC=o64-clang
        export CXX=o64-clang++
        export LD=ld64
        export TARGET=x86_64-apple-darwin20.4
        export OSX_VERSION_MIN=11.0
        export SDKROOT=${pkgs.macosxSDK}

        echo "Using osxcross toolchain:"
        which $CC
        $CC --version
      '';
    };
  };
}
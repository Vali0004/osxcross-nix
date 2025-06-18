{
  description = "osxcross dev env with overridden LLVM";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs = { self, nixpkgs }: let
    system = "x86_64-linux";

    overlays = [(final: prev:
      let
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
        libtapi = pkgs.callPackage ./pkgs/apple-libtapi { llvm = pkgs.llvm_20; };
        cctools = pkgs.callPackage ./pkgs/cctools { inherit libtapi; };
      in {
        llvmPackages_20 = llvmPackagesSet."20";
        clang_20 = llvmPackagesSet."20".clang;
        lld_20 = llvmPackagesSet."20".lld;
        llvm_20 = llvmPackagesSet."20".llvm;

        inherit libtapi cctools;
      }
    )];

    pkgs = import nixpkgs { inherit system overlays; };
  in {
    packages.${system} = {
      llvmPackages_20 = pkgs.llvmPackages_20;
      clang_20 = pkgs.clang_20;
      lld_20 = pkgs.lld_20;
      llvm_20 = pkgs.llvm_20;
    };

    devShell.${system} = pkgs.mkShell {
      name = "osxcross-dev";

      buildInputs = with pkgs; [
        automake autoconf cmake ninja
        curl wget git patch python3
        openssl libxml2 bzip2 xz unzip zlib zlib-ng pkg-config
        clang_20 lld_20
      ];

      shellHook = ''
        export CC=o64-clang
        export CXX=o64-clang++
        export LD=ld.lld
        export TARGET=x86_64-apple-darwin20.4
        export OSX_VERSION_MIN=11.0
        export PATH=$PWD/osxcross/target/bin:$PATH

        echo "Using osxcross toolchain:"
        which $CC
        $CC --version
      '';
    };
  };
}

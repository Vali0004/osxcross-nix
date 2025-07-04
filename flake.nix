{
  description = "osxcross dev env";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs = { self, nixpkgs }: let
    hostSystem = "x86_64-linux";
    targetSystem = "x86_64-apple-darwin20.4";

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

          libcxx = true;
          useLibcxx = true;

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

      libdispatch = prev.swift-corelibs-libdispatch;
      libxar = prev.xar;

      libtapi = prev.callPackage ./pkgs/apple-libtapi {
        inherit libxar;
        llvm = llvmPackagesSet."20".llvm;
      };

      cctools = prev.callPackage ./pkgs/cctools-port {
        inherit libtapi libdispatch libxar;
      };

      wrappedClang = prev.stdenv.mkDerivation {
        pname = "o64-clang-wrapper";
        version = "20.1.5";

        nativeBuildInputs = [ prev.makeWrapper ];

        dontUnpack = true;

        installPhase = ''
          mkdir -p $out/bin

          makeWrapper ${llvmPackagesSet."20".clang.cc}/bin/clang $out/bin/clang \
            --set PATH "${cctools}/bin:$PATH" \
            --add-flags "--target=x86_64-apple-darwin20.4" \
            --add-flags "-isysroot ${macosxSDK}/SDK/MacOSX11.3.sdk" \
            --add-flags "-mmacosx-version-min=11.0" \
            --add-flags "-fuse-ld=${cctools}/bin/ld64"

          makeWrapper ${llvmPackagesSet."20".clang.cc}/bin/clang++ $out/bin/clang++ \
            --set PATH "${cctools}/bin:$PATH" \
            --add-flags "--target=x86_64-apple-darwin20.4" \
            --add-flags "-isysroot ${macosxSDK}/SDK/MacOSX11.3.sdk" \
            --add-flags "-mmacosx-version-min=11.0" \
            --add-flags "-fuse-ld=${cctools}/bin/ld64"
        '';
      };
    in {
      llvmPackages_20 = llvmPackagesSet."20";
      clang_20 = llvmPackagesSet."20".clang;
      lld_20 = llvmPackagesSet."20".lld;
      llvm_20 = llvmPackagesSet."20".llvm;
      inherit macosxSDK libtapi cctools wrappedClang;
    })];
    
    pkgs = import nixpkgs {
      inherit overlays;
      system = hostSystem;
    };

    pkgsCross = import nixpkgs {
      system = hostSystem;
      crossSystem = {
        config = targetSystem;
      };
      overlays = overlays ++ [
        (final: prev: {
          stdenv = prev.libcxxStdenv;
        })
      ];
    };
  in {
    packages.${hostSystem} = {
      inherit (pkgsCross) stdenv;
      osxcrossClang = pkgsCross.wrappedClang;
    };
    inherit (pkgs) overlays;

    devShell.${hostSystem} = pkgs.mkShell {
      name = "osxcross-dev";

      buildInputs = with pkgs; [
        automake autoconf cmake ninja
        curl wget git patch python3
        openssl libxml2 bzip2 xz unzip zlib zlib-ng pkg-config
        wrappedClang lld_20 cctools macosxSDK
      ];

      shellHook = ''
        export CC=${pkgs.wrappedClang}/bin/clang
        export CXX=${pkgs.wrappedClang}/bin/clang++
        export LD=${pkgs.lld_20}/bin/ld64
        export SYSROOT=${pkgs.macosxSDK}
        export OSX_VERSION_MIN=11.0
      '';
    };
  };
}
{ stdenv, cmake, ninja, llvm, fetchFromGitHub }:

stdenv.mkDerivation rec {
  pname = "apple-libtapi";
  version = "1100.0.11";

  src = fetchFromGitHub {
    owner = "tpoechtrager";
    repo = "apple-libtapi";
    rev = "1100.0.11";
    hash = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";
  };

  nativeBuildInputs = [ cmake ninja ];
  buildInputs = [ llvm ];

  cmakeFlags = [
    "-DCMAKE_BUILD_TYPE=Release"
    "-DLLVM_CONFIG=${llvm.dev}/bin/llvm-config"
  ];

  installPhase = ''
    mkdir -p $out/lib $out/include
    cp -r lib/* $out/lib/
    cp -r include/* $out/include/
  '';
}

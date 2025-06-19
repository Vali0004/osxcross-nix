{ stdenv, cmake, ninja, llvm, clang, fetchFromGitHub, python3, lib, makeWrapper }:

stdenv.mkDerivation rec {
  pname = "apple-libtapi";
  version = "1600.0.11.8";

  src = fetchFromGitHub {
    owner = "tpoechtrager";
    repo = "apple-libtapi";
    rev = version;
    hash = "sha256-S0uqhh/OKlRGwqJMLlZlAc6aP37kVmDRWPUa0El9aO4=";
  };

  nativeBuildInputs = [ cmake ninja python3 clang makeWrapper ];
  buildInputs = [ llvm ];

  cmakeDir = "../src/llvm";

  cmakeFlags = [
    "-DCMAKE_BUILD_TYPE=Release"
    "-DCMAKE_C_COMPILER=clang"
    "-DCMAKE_CXX_COMPILER=clang++"
    "-DLLVM_INCLUDE_TESTS=OFF"
    "-DTAPI_REPOSITORY_STRING=${version}"
    "-DTAPI_FULL_VERSION=11.0.0"
    "-DLLVM_CONFIG=${llvm.dev}/bin/llvm-config"
    "-DLLVM_ENABLE_PROJECTS=clang;tapi"
    "-DPYTHON_EXECUTABLE=${python3.interpreter}"
    "-GNinja"
  ];
  
  preConfigure = ''
    export CXXFLAGS="$CXXFLAGS -I${src}/src/llvm/projects/clang/include"
  '';

  buildPhase = ''
    runHook preBuild
    ninja clangBasic vt_gen
    ninja libtapi
    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall
    mkdir -p $out/lib $out/include

    cp -rv lib/* $out/lib/
    cp -rv include/* $out/include/

    runHook postInstall
  '';

  meta = with lib; {
    description = "Apple's libtapi for linking and .tbd file parsing";
    homepage = "https://github.com/tpoechtrager/apple-libtapi";
    license = licenses.apsl20;
    maintainers = with maintainers; [ ];
    platforms = platforms.unix;
  };
}

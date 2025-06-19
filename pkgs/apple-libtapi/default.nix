{ stdenv, cmake, ninja, llvm, fetchFromGitHub, python3, lib, makeWrapper }:

stdenv.mkDerivation rec {
  pname = "apple-libtapi";
  version = "1100.0.11";

  src = fetchFromGitHub {
    owner = "tpoechtrager";
    repo = "apple-libtapi";
    rev = version;
    hash = "sha256-ebW1q0WWq8YCPrA4EuY6CBigxhiWZvBJ8G4pXQ2hPvg=";
  };

  nativeBuildInputs = [ cmake ninja python3 makeWrapper ];
  buildInputs = [ llvm ];

  cmakeDir = "../src/llvm";

  cmakeFlags = [
    "-DCMAKE_BUILD_TYPE=Release"
    "-DLLVM_INCLUDE_TESTS=OFF"
    "-DTAPI_REPOSITORY_STRING=${version}"
    "-DTAPI_FULL_VERSION=11.0.0"
    "-DLLVM_CONFIG=${llvm.dev}/bin/llvm-config"
    "-DPYTHON_EXECUTABLE=${python3.interpreter}"
    "-GNinja"
  ];

  buildPhase = ''
    runHook preBuild
    ninja clangBasic libtapi
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

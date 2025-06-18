{ stdenv, cmake, ninja, libtapi, fetchFromGitHub }:

stdenv.mkDerivation rec {
  pname = "cctools-port";
  version = "20230401";

  src = fetchFromGitHub {
    owner = "tpoechtrager";
    repo = "cctools-port";
    rev = "20230401";
    hash = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";
  };

  nativeBuildInputs = [ cmake ninja ];
  buildInputs = [ libtapi ];

  cmakeFlags = [
    "-DCMAKE_BUILD_TYPE=Release"
    "-DCMAKE_INSTALL_PREFIX=$out"
    "-DLLVM_INCLUDE_DIRS=${libtapi}/include"
    "-DLLVM_LIB_DIRS=${libtapi}/lib"
    "-DLIBTAPI_ROOT_DIR=${libtapi}"
  ];
}
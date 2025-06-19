{ stdenv, cmake, ninja, libtapi, fetchFromGitHub }:

stdenv.mkDerivation rec {
  pname = "cctools-port";
  version = "1024.3-ld64-955.13";

  src = fetchFromGitHub {
    owner = "tpoechtrager";
    repo = "cctools-port";
    rev = "1024.3-ld64-955.13";
    hash = "sha256-kQApmHaL3iTxrH58XVFYDnyK6iR0//Uaz8wcb7dFWF4=";
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
  
  postInstall = ''
    ln -s $out/bin/ld $out/bin/ld64
  '';
}
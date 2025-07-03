{ stdenv
, fetchFromGitHub
, libdispatch
, libtapi
, llvm
, clang
, libxar ? null, libfts ? null
, lib
}:

stdenv.mkDerivation rec {
  pname = "cctools-port";
  version = "1024.3-ld64-955.13";

  src = fetchFromGitHub {
    owner = "tpoechtrager";
    repo = "cctools-port";
    rev = version;
    hash = "sha256-kQApmHaL3iTxrH58XVFYDnyK6iR0//Uaz8wcb7dFWF4=";
  };

  buildInputs = [ libdispatch libtapi llvm clang ]
    ++ lib.optional (libxar != null) libxar
    ++ lib.optional (libfts != null) libfts;

  nativeBuildInputs = [ ];

  preConfigure = ''
    export CC=${clang}/bin/clang
    export CXX=${clang}/bin/clang++
    export CFLAGS="-I${libtapi}/include"
    export LDFLAGS="-L${libtapi}/lib -ltapi"
  '';

  configurePhase = ''
    runHook preConfigure
    cd cctools
    ./configure \
      --prefix=$out \
      --with-libtapi=${libtapi} \
      --with-llvm-config=${llvm.dev}/bin/llvm-config
  '';

  buildPhase = "make -j$NIX_BUILD_CORES";

  installPhase = ''
    make install
    ln -s $out/bin/ld $out/bin/ld64
  '';

  meta = with lib; {
    description = "Apple cctools ported for non-Darwin platforms, including ld64 and as.";
    homepage = "https://github.com/tpoechtrager/cctools-port";
    license = licenses.apsl20;
    maintainers = with maintainers; [ ];
    platforms = platforms.unix;
  };
}

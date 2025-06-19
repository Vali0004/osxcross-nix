{ stdenv, fetchurl, ... }:

stdenv.mkDerivation {
  pname = "MacOSX";
  version = "11.3.sdk";

  src = fetchurl {
    url = "https://github.com/phracker/MacOSX-SDKs/releases/download/11.3/MacOSX11.3.sdk.tar.xz";
    sha256 = "sha256-zU8Ip1V3FFuPBSRaKXX3yBQB116VNdz/u4ee4d7vy/Q=";
  };

  phases = [ "unpackPhase" "installPhase" ];

  sourceRoot = ".";

  installPhase = ''
    mkdir -p $out
    cp -r MacOSX11.3.sdk/* $out/
  '';
}
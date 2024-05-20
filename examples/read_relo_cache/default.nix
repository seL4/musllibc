{ stdenv }:
stdenv.mkDerivation rec {
  name = "read_relo_cache";

  src = ./read_relo_cache.cpp;
  dontUnpack = true;
  dontStrip = true;
  buildPhase = ''
    $CXX -g -O0 -std=c++17 ${src} -o read_relo_cache
  '';
  installPhase = ''
    mkdir -p $out/bin
    cp read_relo_cache $out/bin
  '';
}

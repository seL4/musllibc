{ stdenv, python3 }:
stdenv.mkDerivation {
  name = "raw_functions";
  nativeBuildInputs = [ python3 ];
  src = ./number_of_functions.py;
  dontUnpack = true;
  dontStrip = true;
  NIX_CFLAGS_COMPILE = "-g -O0";
  buildPhase = ''
    for ((i=1; i<=1000000; i*=10)); do
        python3 $src $i
    done
  '';

  installPhase = ''
    mkdir -p $out/bin
    mkdir -p $out/lib

    mv *functions.so $out/lib
    mv *functions $out/bin
  '';
}

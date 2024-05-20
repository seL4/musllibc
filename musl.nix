{ stdenv, lib }:
let # See https://nix.dev/tutorials/file-sets for a guide on how the file set api works
  fs = lib.fileset;
in stdenv.mkDerivation {
  name = "musl";

  enableParallelBuilding = true;
  dontStrip = true;
  NIX_CFLAGS_COMPILE = "-g -O0";

  src = fs.toSource {
    root = ./.;
    fileset = fs.unions [
      ./Makefile
      ./configure
      ./src
      ./ldso
      ./include
      ./crt
      ./arch
      ./tools
    ];
  };
  # Without the disable-optimize frame-pointers are ommitted making perf harder to use
  configureFlags =
    [ "--enable-wrapper=gcc" "--disable-optimize" "--enable-debug" ];
}

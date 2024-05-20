{ stdenv, patchExecutable, lib }:
let
  fs = lib.fileset;
  libfoo = stdenv.mkDerivation rec {
    name = "libfoo";
    src = fs.toSource {
      root = ./.;
      fileset = fs.unions [ ./Makefile ./foo.c ];
    };
    nativeBuildInputs = [ ];
    dontStrip = true;
    buildPhase = ''
      ls -l
      ls -l $src
      make libfoo.so
    '';
    installPhase = ''
      mkdir -p $out/lib
      cp libfoo.so $out/lib
    '';
  };
  hello_world = stdenv.mkDerivation {
    name = "hello_world";
    src = fs.toSource {
      root = ./.;
      fileset = fs.unions [ ./Makefile ./hello_world.c ];
    };
    nativeBuildInputs = [ libfoo ];
    dontStrip = true;
    buildPhase = ''
      make hello_world
    '';
    installPhase = ''
      mkdir -p $out/bin
      cp hello_world $out/bin
    '';
  };

in patchExecutable.individual { executable = hello_world; }

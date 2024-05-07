let
  pkgs = import
    (fetchTarball "https://github.com/NixOS/nixpkgs/archive/nixos-23.11.tar.gz")
    { };
  # See https://nix.dev/tutorials/file-sets for a guide on how the file set api works
  fs = pkgs.lib.fileset;
in with pkgs.stdenv;
rec {

  # Application to read reloc binary
  read_relo_cache = mkDerivation rec {
    name = "read_relo_cache";

    src = ./examples/read_relo_cache.cpp;
    dontUnpack = true;
    nativeBuildInputs = [];
    dontStrip = true;
    buildPhase = ''
        $CXX -g -O0 -std=c++17 ${src} -o read_relo_cache
    '';
    installPhase = ''
        mkdir -p $out/bin
        cp read_relo_cache $out/bin
    '';
  };

  libfoo = mkDerivation rec {
    name = "libfoo";
    src = ./examples/foo.c;
    dontUnpack = true;
    nativeBuildInputs = [ musl pkgs.patchelf];
    dontStrip = true;
    buildPhase = ''
        ${musl}/bin/musl-gcc -g -O0 -o libfoo.so -shared ${src} '-Wl,--no-as-needed,--enable-new-dtags'
    '';
    installPhase = ''
        mkdir -p $out/lib
        cp libfoo.so $out/lib
    '';
  };

   # Application to read reloc binary
  hello_world = mkDerivation rec {
    name = "hello_world";

    src = ./examples/hello_world.c;
    dontUnpack = true;
    nativeBuildInputs = [musl libfoo];
    dontStrip = true;
    buildPhase = ''
        ${musl}/bin/musl-gcc -g -O0 -o hello_world ${src} -lfoo '-Wl,--no-as-needed,--enable-new-dtags'
    '';
    installPhase = ''
        patchelf --set-interpreter ${musl}/lib/libc.so hello_world
        mkdir -p $out/bin
        cp hello_world $out/bin
    '';
  }; 

  # This musl derivation
  musl = mkDerivation {
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

  };
}

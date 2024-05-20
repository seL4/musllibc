{ stdenv, python3, lib }:
let fs = lib.fileset;
in stdenv.mkDerivation {
  name = "raw_functions_and_libraries";
  nativeBuildInputs = [ python3 ];
  src = fs.toSource {
    root = ./.;
    fileset = fs.unions [ ./Makefile ./generate_sources.py ];
  };
  dontStrip = true;
  NIX_CFLAGS_COMPILE = "-g -O0";
  buildPhase = ''
    # Function to generate the shared objects and executable
    generate_files() {
        local num_functions=$1
        local num_shared_objects=$2
        local total_symbols=$((num_functions * num_shared_objects))
        echo "Generating for $total_symbols symbols: $num_functions functions per shared object, $num_shared_objects shared objects"

        mkdir build_''${num_functions}_''${num_shared_objects}
        pushd build_''${num_functions}_''${num_shared_objects}
        python3 $src/generate_sources.py $num_functions $num_shared_objects

        echo "Building with ''${NIX_BUILD_CORES} cores"
        make -f $src/Makefile -j''${NIX_BUILD_CORES}
        # Rename the benchmark executable
        mv benchmark benchmark_''${num_functions}_''${num_shared_objects}
        popd
    }

    for num_functions in 1 10 100 1000; do
      for num_shared_objects in 1 10 100 1000; do
          generate_files $num_functions $num_shared_objects
      done
    done
  '';

  installPhase = ''
    mkdir -p $out/bin
    mkdir -p $out/lib

    mv build_*/*.so $out/lib
    mv build_*/benchmark_*_* $out/bin
  '';
}

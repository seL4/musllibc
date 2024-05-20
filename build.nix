let
  # Consider setting enableParallelBuildingByDefault = true; in your configuration.nix
  # It will likely cause a mass rebuild.
  pkgs = import (fetchTarball
    "https://github.com/NixOS/nixpkgs/archive/nixos-23.11.tar.gz") {
      overlays = [
        (self: super:
          {

          })
      ];
    };
  # See https://nix.dev/tutorials/file-sets for a guide on how the file set api works
  fs = pkgs.lib.fileset;

  # Super important to use pkgsMusl so that the GCC flags that get passed
  # are correct so that the right libc & dynamic linker are used
in with pkgs.pkgsMusl.stdenv; rec {

  # Application to read reloc binary
  read_relo_cache = mkDerivation rec {
    name = "read_relo_cache";

    src = ./examples/read_relo_cache.cpp;
    dontUnpack = true;
    nativeBuildInputs = [ ];
    dontStrip = true;
    buildPhase = ''
      $CXX -g -O0 -std=c++17 ${src} -o read_relo_cache
    '';
    installPhase = ''
      mkdir -p $out/bin
      cp read_relo_cache $out/bin
    '';
  };

  # This musl derivation we are building with our local source
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
    # Without the disable-optimize frame-pointers are ommitted making perf harder to use
    configureFlags =
      [ "--enable-wrapper=gcc" "--disable-optimize" "--enable-debug" ];
  };

  examples =

    let
      patchExecutable = { name, executable, command ? "--version" }:
        pkgs.stdenv.mkDerivation {
          name = "patched_${name}";

          buildInputs = [ pkgs.patchelf musl executable ];

          phases = "installPhase";

          installPhase = ''
            mkdir -p $out/bin
            patchelf --set-interpreter ${musl}/lib/libc.so ${executable}/bin/${name} --output $out/bin/${name}
            RELOC_WRITE=1 $out/bin/${name} ${command}
            cp relo.bin $out/bin
            objcopy --add-section .reloc.cache=relo.bin \
                    --set-section-flags .reloc.cache=noload,readonly $out/bin/${name}
          '';
        };
    in rec {
      raw_functions_and_libraries = mkDerivation rec {
        name = "raw_functions_and_libraries";
        # the musl.dev variant is important to provide musl-gcc
        nativeBuildInputs = [ pkgs.python3 pkgs.musl.dev ];
        src = fs.toSource {
          root = ./.;
          fileset = fs.unions [
            ./examples/benchmark-many-files-dynamic/Makefile
            ./examples/benchmark-many-files-dynamic/generate_sources.py
          ];
        };
        dontStrip = true;
        enableParallelBuilding = true;
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
              ${pkgs.python3}/bin/python3 $src/examples/benchmark-many-files-dynamic/generate_sources.py $num_functions $num_shared_objects

              echo "Building with ''${NIX_BUILD_CORES} cores"
              make -f $src/examples/benchmark-many-files-dynamic/Makefile -j''${NIX_BUILD_CORES}
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
      };

      patched_functions_and_libraries = mkDerivation {
        name = "patched_functions_and_libraries";

        buildInputs = [ raw_functions_and_libraries pkgs.patchelf musl ];

        phases = "installPhase";

        installPhase = ''
          mkdir -p $out/bin

          # Apply patchelf to all binaries in the bin directory to set the new interpreter.
          for bin in ${raw_functions_and_libraries}/bin/*; do
              patchelf --set-interpreter ${musl}/lib/libc.so $bin --output $out/bin/$(basename $bin)
          done

          # Add the custom relocation section
          for bin in $out/bin/*; do
            RELOC_WRITE=1 $bin &>/dev/null
            objcopy --add-section .reloc.cache=relo.bin \
                    --set-section-flags .reloc.cache=noload,readonly $bin
          done
        '';
      };

      # we create the raw_functions separate to avoid recreating them when
      # our musl code changes. Therefore we create a wrapped attribute that
      # sets the interpreter. Technically the libc are not the same but
      # the ABI should be compatible..... I think.
      raw_functions = mkDerivation rec {
        name = "raw_functions";
        # the musl.dev variant is important to provide musl-gcc
        nativeBuildInputs = [ pkgs.python3 pkgs.musl.dev ];
        src = ./examples/number_of_functions.py;
        dontUnpack = true;
        dontStrip = true;
        NIX_CFLAGS_COMPILE = "-g -O0";
        buildPhase = ''
          # Function to generate the shared objects and executable
          generate_files() {
              local num_functions=$1
              local num_shared_objects=$2
              local total_symbols=$((num_functions * num_shared_objects))

              echo "Generating for $total_symbols symbols: $num_functions functions per shared object, $num_shared_objects shared objects"
              ${pkgs.python3}/bin/python3 ${src} $num_functions $num_shared_objects
          }

          # Iterate over powers of 10 up to 1 million
          for total_symbols in 10 100 1000 10000 100000 1000000; do
            echo "Processing total_symbols = $total_symbols"
            for num_shared_objects in 1 10 100 1000 10000; do
                if ((num_shared_objects <= total_symbols && total_symbols % num_shared_objects == 0)); then
                    num_functions=$((total_symbols / num_shared_objects))
                    generate_files $num_functions $num_shared_objects
                fi
            done
          done
        '';

        installPhase = ''
          mkdir -p $out/bin
          mkdir -p $out/lib

          mv *functions.so $out/lib
          mv *functions $out/bin
        '';
      };

      patched_functions = mkDerivation {
        name = "patched_functions";

        buildInputs = [ raw_functions pkgs.patchelf musl ];

        phases = "installPhase";

        installPhase = ''
          mkdir -p $out/bin

          # Apply patchelf to all binaries in the bin directory to set the new interpreter.
          for bin in ${raw_functions}/bin/*; do
              patchelf --set-interpreter ${musl}/lib/libc.so $bin --output $out/bin/$(basename $bin)
          done

          # Add the custom relocation section
          for bin in $out/bin/*; do
            RELOC_WRITE=1 $bin &>/dev/null
            objcopy --add-section .reloc.cache=relo.bin \
                    --set-section-flags .reloc.cache=noload,readonly $bin
          done
        '';
      };

      patched_ruby = let
        # for some reason on pkgMusl this is hanging?...
        # just disable it for now
        libffi = pkgs.pkgsMusl.libffi.overrideAttrs (oldAttrs: {
          doCheck = false; # Disable the check phase
        });
        ruby = pkgs.enableDebugging
          (pkgs.pkgsMusl.ruby.override { libffi = libffi; });
      in patchExecutable {
        name = "ruby";
        executable = ruby;
      };

      patched_clang = pkgs.pkgsMusl.wrapCC (patchExecutable {
        name = "clang";
        executable = pkgs.pkgsMusl.llvmPackages.clang.cc;
      });

      patched_python = patchExecutable {
        name = "python3";
        executable = pkgs.enableDebugging pkgs.pkgsMusl.python3;
      };

      libfoo = mkDerivation rec {
        name = "libfoo";
        src = ./examples/foo.c;
        dontUnpack = true;
        nativeBuildInputs = [ musl pkgs.patchelf ];
        dontStrip = true;
        buildPhase = ''
          ${musl}/bin/musl-gcc -g -O0 -o libfoo.so -shared ${src} \
                               '-Wl,--no-as-needed,--enable-new-dtags'
        '';
        installPhase = ''
          mkdir -p $out/lib
          cp libfoo.so $out/lib
        '';
      };

      hello_world = patchExecutable {
        name = "hello_world";
        executable = mkDerivation rec {
          name = "hello_world";

          src = ./examples/hello_world.c;
          dontUnpack = true;
          nativeBuildInputs = [ musl libfoo ];
          dontStrip = true;
          buildPhase = ''
            ${musl}/bin/musl-gcc -g -O0 -o hello_world ${src} -lfoo '-Wl,--no-as-needed,--enable-new-dtags'
          '';
          installPhase = ''
            mkdir -p $out/bin
            cp hello_world $out/bin
          '';
        };
      };
    };

  benchmarks = {
    benchmark-1000000_functions =
      pkgs.writeShellScriptBin "run-1000000_functions-benchmark" ''
        ${pkgs.hyperfine}/bin/hyperfine --warmup 3 --runs 10 \
                'RELOC_READ=1 ${examples.patched_functions}/bin/1000000_functions  &>/dev/null' \
                '${examples.patched_functions}/bin/1000000_functions  &>/dev/null' --export-json benchmark.json
      '';
    benchark-multiple-functions-per-shared-object = pkgs.writeShellScriptBin
      "run-multiple-functions-per-shared-object-benchmark" ''
        # Output file for CSV results
        results_file="benchmark_results.csv"
        echo "binary,baseline_time,reloc_read_time,median_speedup" > $results_file

        # Function to run benchmarks and collect data
        run_benchmark() {
            local binary=$1
            local results_file=$2

            echo "Benchmarking $binary"

            if [[ "$binary" == *"benchmark_1000_1000"* ]]; then
                # Configuration for benchmark_1000_1000
                # it takes so long so run it a few less times
                runs=3
                warmup=1
            else
                # Default configuration
                runs=100
                warmup=3
            fi

            ${pkgs.hyperfine}/bin/hyperfine --warmup $warmup --runs $runs \
                  --export-json baseline.json $binary --shell=none --output null
            RELOC_READ=1 ${pkgs.hyperfine}/bin/hyperfine --warmup $warmup --runs $runs \
                  --export-json reloc_read.json $binary --shell=none --output null

            baseline_mean=$(jq '.results[0].mean' baseline.json)
            reloc_read_mean=$(jq '.results[0].mean' reloc_read.json)
            speedup=$(echo "scale=4; $baseline_mean / $reloc_read_mean" | bc)

            echo "$(basename $binary),$baseline_mean,$reloc_read_mean,$speedup" >> $results_file

            rm baseline.json reloc_read.json
        }

        # Run benchmarks for each binary
        for binary in ${examples.patched_functions_and_libraries}/bin/benchmark_*_*; do
            run_benchmark $binary $results_file
        done

        echo "Benchmarking completed. Results saved to $results_file."
      '';
  };

  flamegraphs = {

    baseline = pkgs.writeShellScriptBin "create-flamegraph" ''
      perf record -F 300 -g -a --user-callchains -- ${examples.patched_functions}/bin/1000000_functions > /dev/null
      perf script > out.perf
      ${pkgs.flamegraph}/bin/stackcollapse-perf.pl out.perf > out.perf-folded
      grep _dlstart_c out.perf-folded > _dlstart_c-out.perf-folded
      ${pkgs.flamegraph}/bin/flamegraph.pl --title ' ' _dlstart_c-out.perf-folded > baseline.svg
      echo $(realpath baseline.svg)
    '';

    modified = pkgs.writeShellScriptBin "create-flamegraph" ''
      RELOC_READ=1 perf record -F 300 -g -a --user-callchains -- ${examples.patched_functions}/bin/1000000_functions > /dev/null
      perf script > out.perf
      ${pkgs.flamegraph}/bin/stackcollapse-perf.pl out.perf > out.perf-folded
      grep _dlstart out.perf-folded > _dlstart-out.perf-folded
      ${pkgs.flamegraph}/bin/flamegraph.pl --title ' ' _dlstart-out.perf-folded > modified.svg
      echo $(realpath modified.svg)
    '';

  };

}

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
  # taken from https://nix.dev/tutorials/callpackage
  callPackage = pkgs.lib.callPackageWith (pkgs.pkgsMusl // packages);
  packages = rec {
    patchExecutable = callPackage ./patch_executable.nix { };
    musl = callPackage ./musl.nix { };
    read_relo_cache = callPackage ./examples/read_relo_cache { };
    examples = rec {
      # creates binaries with variying number of functions and shared objects
      raw_functions_and_libraries =
        callPackage ./examples/benchmark-many-files-dynamic { };
      patched_functions_and_libraries = patchExecutable.all {
        executable = raw_functions_and_libraries;
        command = "&>/dev/null";
      };
      # creates binaries with varying number of functions.
      # this derivation may be superseded by raw_functions_and_libraries
      raw_functions = callPackage ./examples/benchmark-many-functions { };
      patched_functions = patchExecutable.all {
        executable = raw_functions;
        command = "&>/dev/null";
      };
      hello_world = callPackage ./examples/hello-world { };
    } // callPackage ./examples { };
  };
  benchmarks = {
    benchmark-1000000_functions =
      pkgs.writeShellScriptBin "run-1000000_functions-benchmark" ''
        ${pkgs.hyperfine}/bin/hyperfine --warmup 3 --runs 10 \
                'RELOC_READ=1 ${packages.examples.patched_functions}/bin/1000000_functions  &>/dev/null' \
                '${packages.examples.patched_functions}/bin/1000000_functions  &>/dev/null' --export-json benchmark.json
      '';
  };
  # Super important to use pkgsMusl so that the GCC flags that get passed
  # are correct so that the right libc & dynamic linker are used
in with pkgs.pkgsMusl.stdenv; {

  inherit packages;

  benchmarks = benchmarks // {
    
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

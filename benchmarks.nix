{ writeShellScriptBin, hyperfine, examples, lib }:
lib.recurseIntoAttrs {
  benchmark-1000000_functions =
    writeShellScriptBin "run-1000000_functions-benchmark" ''
      ${hyperfine}/bin/hyperfine --warmup 3 --runs 10 \
              'RELOC_READ=1 ${examples.patched_functions}/bin/1000000_functions  &>/dev/null' \
              '${examples.patched_functions}/bin/1000000_functions  &>/dev/null' --export-json benchmark.json
    '';

  benchark-multiple-functions-per-shared-object =
    writeShellScriptBin "run-multiple-functions-per-shared-object-benchmark" ''
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

          ${hyperfine}/bin/hyperfine --warmup $warmup --runs $runs \
                --export-json baseline.json $binary --shell=none --output null
          RELOC_READ=1 ${hyperfine}/bin/hyperfine --warmup $warmup --runs $runs \
                --export-json reloc_read.json $binary --shell=none --output null

          baseline_mean=$(jq '.results[0].mean' baseline.json)
          reloc_read_mean=$(jq '.results[0].mean' reloc_read.json)
          speedup=$(echo "scale=4; $baseline_mean / $reloc_read_mean" | bc)

          echo "$(basename $binary),$baseline_mean,$reloc_read_mean,$speedup" >> $results_file

          rm baseline.json reloc_read.json
      }

      # Run benchmarks for each binary
      for binary in ${examples.patched_functions_and_libraries}/bin/benchmark_*_*; do
          [[ $binary == *.relo ]] && continue
          run_benchmark $binary $results_file
      done

      echo "Benchmarking completed. Results saved to $results_file."
    '';
}

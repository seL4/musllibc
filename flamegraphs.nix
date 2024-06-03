{ writeShellScriptBin, flamegraph, examples, lib }:
lib.recurseIntoAttrs {

  baseline = writeShellScriptBin "create-flamegraph" ''
    perf record -F 300 -g -a --user-callchains -- ${examples.patched_functions}/bin/1000000_functions > /dev/null
    perf script > out.perf
    ${flamegraph}/bin/stackcollapse-perf.pl out.perf > out.perf-folded
    grep _dlstart_c out.perf-folded > _dlstart_c-out.perf-folded
    ${flamegraph}/bin/flamegraph.pl --title ' ' _dlstart_c-out.perf-folded > baseline.svg
    echo $(realpath baseline.svg)
  '';

  modified = writeShellScriptBin "create-flamegraph" ''
    RELOC_READ=1 perf record -F 300 -g -a --user-callchains -- ${examples.patched_functions}/bin/1000000_functions > /dev/null
    perf script > out.perf
    ${flamegraph}/bin/stackcollapse-perf.pl out.perf > out.perf-folded
    grep _dlstart out.perf-folded > _dlstart-out.perf-folded
    ${flamegraph}/bin/flamegraph.pl --title ' ' _dlstart-out.perf-folded > modified.svg
    echo $(realpath modified.svg)
  '';

}

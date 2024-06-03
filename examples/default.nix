{ libffi, ruby, patchExecutable, wrapCC, llvmPackages, enableDebugging, python3
, stdenv, fetchFromGitHub, python2, openmpi, makeWrapper, lib }:
lib.recurseIntoAttrs {
  patched_ruby = let
    # for some reason on pkgMusl this is hanging?...
    # just disable it for now
    modified_libffi = libffi.overrideAttrs (oldAttrs: {
      doCheck = false; # Disable the check phase
    });
    modified_ruby = enableDebugging (ruby.override { libffi = libffi; });
  in patchExecutable.individual { executable = modified_ruby; };

  patched_clang =
    wrapCC (patchExecutable.individual { executable = llvmPackages.clang.cc; });

  patched_python =
    patchExecutable.individual { executable = enableDebugging python3; };

  pynamic = stdenv.mkDerivation rec {
    name = "pynamic";
    src = fetchFromGitHub {
      owner = "LLNL";
      repo = "pynamic";
      rev = "4b17259e5171628b0f08e7cd7ddf72bcd5e19d9f";
      hash = "sha256-5npWRktvH4luT4qw6z0BJr/twQLu+2HvJ4g8cai11LA=";
    };
    sourceRoot = "${src.name}/pynamic-pyMPI-2.6a1";
    buildInputs = [ python2 openmpi makeWrapper ];

    configurePhase = "";

    postPatch = "";

    buildPhase = ''
      # https://asc.llnl.gov/sites/asc/files/2020-09/pynamic-coral-2-benchmark-summary-v1-2.pdf
      # 900 : num_files
      # 1250 : avg_num_functions
      # -e : enables external functions to call across modules
      # -u <num_utility_mods> <avg_num_u_functions>
      # -n: add N characters to the function name
      # -b : generate the pynamic-bigexe-pyMPI
      python config_pynamic.py 900 1250 -e -u 350 1250 \
                            -n 150 -b -j $NIX_BUILD_CORES
    '';

    installPhase = ''
      mkdir -p $out/bin
      mkdir -p $out/lib

      mv pynamic-bigexe-pyMPI  $out/bin
      mv pynamic_driver.py $out/bin

      mv *.so $out/lib

      makeWrapper $out/bin/pynamic-bigexe-pyMPI $out/bin/pynamic-bigexe \
                    --set PYTHONPATH "$out/lib" \
                    --add-flags $out/bin/pynamic_driver.py
    '';
  };
}

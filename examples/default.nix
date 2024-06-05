{ openssh, musl, patchelf, libffi, ruby, patchExecutable, wrapCC, llvmPackages, enableDebugging, python3
, stdenv, fetchFromGitHub, openmpi, makeWrapper, lib }:
lib.recurseIntoAttrs rec {
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
    buildInputs = [ (python3.withPackages(ps: [ ps.mpi4py ]))  openmpi makeWrapper ];

    configurePhase = ''
      # do nothing
    '';

    buildPhase = ''
      # https://asc.llnl.gov/sites/asc/files/2020-09/pynamic-coral-2-benchmark-summary-v1-2.pdf
      # 900 : num_files
      # 1250 : avg_num_functions
      # -e : enables external functions to call across modules
      # -u <num_utility_mods> <avg_num_u_functions>
      # -n: add N characters to the function name
      # -b : generate the pynamic-bigexe-pyMPI
      # python config_pynamic.py 900 1250 -e -u 350 1250 \
      #                      -n 150 -b -j $NIX_BUILD_CORES
      python3 config_pynamic.py 4 4 -e -u 2 2 -n 3 -j $NIX_BUILD_CORES --with-mpi4py
    '';

    installPhase = ''
      mkdir -p $out/bin
      mkdir -p $out/lib

      mv pynamic-mpi4py $out/bin
      mv pynamic_driver_mpi4py.py $out/bin

      mv *.so $out/lib
    '';

  };

  patched_pynamic = stdenv.mkDerivation {
    name = "patched_pynamic";
    phases = "installPhase";
    buildInputs = [ patchelf musl pynamic makeWrapper openssh];
    installPhase = ''
        mkdir -p $out/bin
        patchelf --set-interpreter ${musl}/lib/libc.so ${pynamic}/bin/pynamic-mpi4py --output $out/bin/pynamic-mpi4py
        PYTHONPATH="${pynamic}/lib:${pynamic}/bin" RELOC_WRITE=1 $out/bin/pynamic-mpi4py -v
        cp relo.bin $out/bin/pynamic-mpi4py.relo
        objcopy --add-section .reloc.cache=relo.bin \
                --set-section-flags .reloc.cache=noload,readonly $out/bin/pynamic-mpi4py
        
        makeWrapper $out/bin/pynamic-mpi4py $out/bin/pynamic-mpi4py-wrapped \
                    --set PYTHONPATH "${pynamic}/lib:${pynamic}/bin"
    '';
  };
}

{ libffi, ruby, patchExecutable, wrapCC, llvmPackages, enableDebugging, python3
, stdenv, fetchFromGitHub, python2, openmpi, lib }: lib.recurseIntoAttrs {
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
      rev = "1.3.4";
      hash = "sha256-YBQiYu4TgxsfmV9iuh0QZNo9GTkgpDn0eFNza1qdnWM=";
    };
    sourceRoot = "${src.name}/pynamic-pyMPI-2.6a1";
    buildInputs = [ python2 openmpi ];
    configureFlags = [ "--with-python=${python2}/bin/python" ];
  };
}

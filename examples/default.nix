{ libffi, ruby, patchExecutable, wrapCC, llvmPackages, enableDebugging, python3
}: {
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

  patched_python = patchExecutable.individual { executable = enableDebugging python3; };
}

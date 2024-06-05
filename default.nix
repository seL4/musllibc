let
  # Consider setting enableParallelBuildingByDefault = true; in your configuration.nix
  # It will likely cause a mass rebuild.
  pkgs = import (fetchTarball
    "https://github.com/NixOS/nixpkgs/archive/nixos-23.11.tar.gz") {
      overlays = [
        (self: super:
          {

          })
        (import ./overlay.nix)  
      ];
    };
  lib = pkgs.lib;
  # taken from https://nix.dev/tutorials/callpackage
  callPackage = pkgs.lib.callPackageWith (pkgs.pkgsMusl // packages);
  packages = pkgs.lib.recurseIntoAttrs rec {
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
    } // callPackage ./examples {
      musl = musl;
      fetchFromGitHub = pkgs.fetchFromGitHub;
    };
  };
  # We actually use pkgs.callPackage here because we don't necessarily
  # need the musl package set so this avoids a lot of rebuilds.
  benchmarks =
    pkgs.callPackage ./benchmarks.nix { examples = packages.examples; };
  flamegraphs =
    pkgs.callPackage ./flamegraphs.nix { examples = packages.examples; };
  # Super important to use pkgsMusl so that the GCC flags that get passed
  # are correct so that the right libc & dynamic linker are used
  # recurseIntoAttrs makes nix-build build everything
  # must be set on each attrset
  # https://discourse.nixos.org/t/nix-build-a-set-of-sets-of-derivations/11291/2
in pkgs.lib.recurseIntoAttrs { inherit packages benchmarks flamegraphs; }

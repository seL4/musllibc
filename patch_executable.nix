{ stdenv, patchelf, musl }:
{ executable, command ? "--version" }:
stdenv.mkDerivation {
  name = "patched_${executable.name}";

  buildInputs = [ patchelf musl executable ];

  phases = "installPhase";

  installPhase = ''
    mkdir -p $out/bin
    # Apply patchelf to all binaries in the bin directory to set the new interpreter.
    for bin in ${executable}/bin/*; do
        patchelf --set-interpreter ${musl}/lib/libc.so $bin --output $out/bin/$(basename $bin)
    done
    # Add the custom relocation section
    for bin in $out/bin/*; do
        RELOC_WRITE=1 $bin ${command}
        cp relo.bin $out/bin/$(basename $bin).relo
        objcopy --add-section .reloc.cache=relo.bin \
            --set-section-flags .reloc.cache=noload,readonly $bin
    done
  '';
}

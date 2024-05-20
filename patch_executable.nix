{ stdenv, patchelf, musl, lib }: {
  all = { name ? lib.strings.getName executable, executable
    , command ? "--version" }:
    stdenv.mkDerivation {
      name = "patched_${name}";

      buildInputs = [ patchelf musl executable ];

      phases = "installPhase";

      installPhase = ''
        mkdir -p $out/bin
        # Apply patchelf to all binaries in the bin directory to set the new interpreter.
        for bin in ${executable}/bin/*; do
            # Check if the file is executable
            if [[ ! -x "$bin" ]]; then
                continue
            fi

            # Check if the file is an ELF binary
            if ! file "$bin" | grep -q "ELF"; then
                continue
            fi
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
    };

  individual = { name ? lib.strings.getName executable, executable
    , command ? "--version" }:
    stdenv.mkDerivation {
      name = "patched_${name}";

      buildInputs = [ patchelf musl executable ];

      phases = "installPhase";

      installPhase = ''
        mkdir -p $out/bin
        patchelf --set-interpreter ${musl}/lib/libc.so ${executable}/bin/${name} --output $out/bin/${name}
        RELOC_WRITE=1 $out/bin/${name} ${command}
        cp relo.bin $out/bin/${name}.relo
        objcopy --add-section .reloc.cache=relo.bin \
                --set-section-flags .reloc.cache=noload,readonly $out/bin/${name}
      '';
    };

}

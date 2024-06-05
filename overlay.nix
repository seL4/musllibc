self: super:
{
  # create a super basic openmpi
  # that doesn't have a lot of the stuff needed so we can build
  # with musl
  openmpi = (super.openmpi.override {
        fabricSupport = false;
        fortranSupport = false;
        cudaSupport = false;
        enableSGE = false;
      }).overrideAttrs (finalAttrs: previousAttrs: {
        enableParallelBuilding = true;
        buildInputs = with super.pkgs; [ zlib libevent hwloc ];
        configureFlags = [
          "--disable-mpi-fortran"
          "--disable-static"
          "--enable-mpi1-compatibility"
        ];
      });
  
  mpi = self.openmpi;
}